const axios = require('axios');
const crypto = require('crypto');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { creditReferralCommissionSafely } = require('../wallet/commission');
const { parseAmount } = require('../wallet/money');

const CLIENT_ID     = "IDv3AhwoKTFpKlptDHujeksgg0xu5k2b";
const API_KEY       = "SKcroiysOoPhMKfR43LxTh8gvCzXTBsK2a5H63Tfxt";
const CHECKSUM_KEY  = "CHKtTSu5oRqvWfrkKItGkyj23MElziHKdFk";

const axiosClient = axios.create({
    baseURL: 'https://api.clickpesa.com/third-parties',
    headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
});

const packagesCol = "packages";
const subscriptionsCol = "subscriptions";
const usersCol = "users";

// Recursively sorts object keys so the same data always serializes the same
// way, regardless of insertion order — required for the checksum to match
// what ClickPesa computes on their end.
function canonicalize(obj) {
    if (obj === null || typeof obj !== 'object') return obj;
    if (Array.isArray(obj)) return obj.map(canonicalize);
    return Object.keys(obj).sort().reduce((acc, key) => {
        acc[key] = canonicalize(obj[key]);
        return acc;
    }, {});
}

function computeChecksum(payload) {
    const canonicalPayload = canonicalize(payload);
    const payloadString = JSON.stringify(canonicalPayload);
    return crypto.createHmac("sha256", CHECKSUM_KEY).update(payloadString).digest("hex");
}

// Accepts whatever shape the client sends (with/without "+", leading 0, etc)
// and normalizes to ClickPesa's expected "255712345678" format.
function normalizePhone(phone) {
    let digits = String(phone || "").replace(/[^\d]/g, "");
    if (digits.startsWith("0")) digits = "255" + digits.slice(1);
    if (!digits.startsWith("255")) digits = "255" + digits;
    return digits;
}

// Logs enough of a ClickPesa HTTP failure to diagnose it from Cloud Logging
// alone: which call failed, its status, and the raw (possibly non-JSON) body.
function logClickPesaError(label, error) {
    console.error(`${label} failed:`, {
        message: error.message,
        code: error.code,
        status: error.response?.status,
        statusText: error.response?.statusText,
        data: typeof error.response?.data === 'string'
            ? error.response.data.slice(0, 500)
            : JSON.stringify(error.response?.data)?.slice(0, 500),
        url: error.config?.url,
    });
}

async function getAuthToken() {
    let resp;
    try {
        // ClickPesa's server tries to JSON-parse whatever body we send, so an
        // empty object (not null/undefined — those serialize to the literal
        // text "null", which its parser rejects) is required here.
        resp = await axiosClient.post('/generate-token', {}, {
            headers: { "client-id": CLIENT_ID, "api-key": API_KEY },
        });
    } catch (error) {
        logClickPesaError('generate-token', error);
        throw error;
    }
    if (!resp.data?.success || !resp.data?.token) {
        throw new Error("ClickPesa auth failed");
    }
    // ClickPesa's token already comes back as "Bearer <jwt>" — do not prepend
    // "Bearer " again when using it as the Authorization header value.
    return resp.data.token;
}

const subscribeClickPesa = onRequest(
    { cors: true },
    async (req, res) => {
        try {
            const db = getFirestore();
            const { userId, packageId, phoneNumber } = req.body;

            if (!userId || !packageId || !phoneNumber) {
                return res.status(400).json({
                    error: { message: "userId, packageId, and phoneNumber are required" }
                });
            }

            const packageDoc = await db.collection(packagesCol).doc(packageId).get();
            if (!packageDoc.exists) {
                return res.status(404).json({ error: { message: "Package not found" } });
            }
            const pkg = packageDoc.data();

            if (!pkg.isActive) {
                return res.status(400).json({ error: { message: "Package is not available" } });
            }

            const userDoc = await db.collection(usersCol).doc(userId).get();
            if (!userDoc.exists) {
                return res.status(404).json({ error: { message: "User not found" } });
            }

            const normalizedPhone = normalizePhone(phoneNumber);

            // Create the subscription record first so its 20-char alphanumeric
            // Firestore doc ID can be used as ClickPesa's orderReference.
            const subscriptionRef = db.collection(subscriptionsCol).doc();

            const authKey = await getAuthToken();

            const pushPayload = {
                amount: String(pkg.price),
                currency: "TZS",
                orderReference: subscriptionRef.id,
                phoneNumber: normalizedPhone,
            };
            const checksum = computeChecksum(pushPayload);

            let pushResp;
            try {
                pushResp = await axiosClient.post(
                    '/payments/initiate-ussd-push-request',
                    { ...pushPayload, checksum, checksumMethod: "canonical" },
                    { headers: { Authorization: authKey } }
                );
            } catch (error) {
                logClickPesaError('initiate-ussd-push-request', error);
                throw error;
            }
            const push = pushResp.data;

            await subscriptionRef.set({
                userId,
                packageId,
                packageName: pkg.name,
                durationDays: pkg.durationDays,
                amount: pkg.price,
                currency: "TZS",
                provider: "clickpesa",
                phoneNumber: normalizedPhone,
                clickpesa_id: push.id,
                order_reference: subscriptionRef.id,
                channel: push.channel,
                status: push.status || "PROCESSING",
                created_at: FieldValue.serverTimestamp(),
            });

            return res.json({
                error: null,
                status: push.status,
                orderReference: subscriptionRef.id,
                subscription_id: subscriptionRef.id,
            });

        } catch (error) {
            const message = error.response?.data?.message || error.message || String(error);
            console.error("subscribeClickPesa error:", message);
            return res.status(500).json({ error: { message } });
        }
    }
);

// ClickPesa's statuses for a payment that has actually been collected.
// Anything else (PROCESSING, PENDING, ON-HOLD, REFUNDED, REVERSED, …) never
// activates a subscription.
const CLICKPESA_SUCCESS_STATUSES = ["SUCCESS", "SETTLED"];

// Whether a verified provider amount covers what the subscription costs
// (subscriptions/{id}.amount = package price recorded at checkout).
function coversExpectedAmount(subscription, collected) {
    const paid = parseAmount(collected);
    if (!Number.isFinite(paid) || paid <= 0) return false;
    const expected = parseAmount(subscription && subscription.amount);
    return !Number.isFinite(expected) || expected <= 0 || paid >= expected;
}

// Asks ClickPesa itself what happened to `orderReference`
// (GET /payments/{orderReference}, "Query Payment Status"). The webhook body
// is never trusted on its own — anyone who knows an orderReference could
// POST a fake "PAYMENT RECEIVED" — so, like the PesaPal IPN path, the
// status and amount used below come only from this authenticated lookup.
// Returns the payment record, or null if ClickPesa has none.
async function fetchClickPesaPayment(orderReference) {
    const authKey = await getAuthToken();
    let resp;
    try {
        resp = await axiosClient.get(
            `/payments/${encodeURIComponent(orderReference)}`,
            { headers: { Authorization: authKey } }
        );
    } catch (error) {
        if (error.response?.status === 404) return null;
        logClickPesaError('query-payment-status', error);
        throw error;
    }
    // The API answers with an array of payment records; only one for this
    // exact orderReference counts.
    const body = resp.data;
    const records = Array.isArray(body) ? body : (body ? [body] : []);
    return records.find((r) => r && r.orderReference === orderReference) || null;
}

// ClickPesa webhook target — registered manually in their merchant dashboard
// under Settings → Developers → Add Webhooks for PAYMENT RECEIVED / PAYMENT FAILED.
const resolvePaymentClickPesa = onRequest(
    { cors: true },
    async (req, res) => {
        const db = getFirestore();
        const { data } = req.body || {};

        if (!data?.orderReference) {
            console.warn("resolvePaymentClickPesa: missing data.orderReference", req.body);
            return res.status(200).json({ error: null, ignored: true });
        }

        // A checksum that is present must be right. One that is absent is
        // tolerated (ClickPesa only signs webhooks when a checksum key is
        // configured on the merchant account), because the payment is
        // verified with ClickPesa's API below either way.
        const { checksum, checksumMethod, ...unsigned } = data;
        if (checksum && computeChecksum(unsigned) !== checksum) {
            console.error("resolvePaymentClickPesa: checksum mismatch", data.orderReference);
            return res.status(200).json({ error: null, rejected: "checksum mismatch" });
        }

        const subscriptionRef = db.collection(subscriptionsCol).doc(data.orderReference);
        try {
            const subscriptionSnap = await subscriptionRef.get();
            if (!subscriptionSnap.exists) {
                console.warn("resolvePaymentClickPesa: subscription not found", data.orderReference);
                return res.status(200).json({ error: null, ignored: true });
            }
            const subscription = subscriptionSnap.data();

            // Never downgrade or re-process a completed payment (a late or
            // duplicated webhook). The commission call is idempotent, so it
            // is retried here in case it failed the first time.
            if (subscription.status === "Completed") {
                await creditReferralCommissionSafely(data.orderReference, db);
                return res.status(200).json({ error: null, activated: true, alreadyCompleted: true });
            }

            let payment;
            try {
                payment = await fetchClickPesaPayment(data.orderReference);
            } catch (error) {
                // Couldn't verify right now — answer 5xx so ClickPesa retries
                // the webhook later instead of us trusting its body.
                return res.status(503).json({ error: { message: "payment verification unavailable" } });
            }

            if (!payment) {
                console.warn("resolvePaymentClickPesa: ClickPesa has no payment for", data.orderReference);
                return res.status(200).json({ error: null, ignored: true, reason: "unverified" });
            }
            const verifiedStatus = String(payment.status || "").toUpperCase();
            const isPaid = CLICKPESA_SUCCESS_STATUSES.includes(verifiedStatus);
            // Paid, but less than the package price → recorded, not activated.
            const isUnderpaid = isPaid && !coversExpectedAmount(subscription, payment.collectedAmount);
            const isCompleted = isPaid && !isUnderpaid;
            const isFailed = verifiedStatus === "FAILED";
            if (isUnderpaid) {
                console.error("resolvePaymentClickPesa: underpaid", data.orderReference,
                    { collected: payment.collectedAmount, expected: subscription.amount });
            }

            const batch = db.batch();
            batch.set(subscriptionRef, {
                payment_status_description: verifiedStatus,
                message: payment.message ?? data.message ?? null,
                payment_amount: payment.collectedAmount ?? null,
                channel: payment.channel ?? data.channel ?? null,
                clickpesa_payment_id: payment.id ?? null,
                status: isCompleted ? "Completed"
                    : (isUnderpaid ? "Underpaid" : (isFailed ? "Failed" : verifiedStatus)),
                updated_at: FieldValue.serverTimestamp(),
            }, { merge: true });

            if (isCompleted) {
                const activatedAt = new Date();
                const expiresAt = new Date(activatedAt);
                expiresAt.setDate(expiresAt.getDate() + (subscription.durationDays || 30));

                batch.set(subscriptionRef, {
                    activated_at: activatedAt.toISOString(),
                    expires_at: expiresAt.toISOString(),
                }, { merge: true });

                const userRef = db.collection(usersCol).doc(subscription.userId);
                batch.set(userRef, {
                    isActive: true,
                    subscriptionExpiry: expiresAt,
                    activePackageId: subscription.packageId,
                    activeSubscriptionId: data.orderReference,
                }, { merge: true });
            }

            await batch.commit();

            // 1% of this payment to whoever referred the payer, once per
            // subscription. The creditReferralOnCompletion trigger is the
            // backstop if this inline call fails.
            if (isCompleted) {
                await creditReferralCommissionSafely(data.orderReference, db);
            }

            return res.status(200).json({ error: null, activated: isCompleted });

        } catch (error) {
            console.error("resolvePaymentClickPesa error:", error);
            // Still 200 — a 5xx here just causes ClickPesa to retry a webhook
            // whose failure is on our side, not theirs.
            return res.status(200).json({ error: { message: error.message || String(error) } });
        }
    }
);

module.exports = {
    subscribeClickPesa,
    resolvePaymentClickPesa,
    fetchClickPesaPayment,
    coversExpectedAmount,
    CLICKPESA_SUCCESS_STATUSES,
};
