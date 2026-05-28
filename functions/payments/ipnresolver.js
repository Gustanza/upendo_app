const axios = require('axios');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onRequest } = require('firebase-functions/v2/https');

const CONSUMER_KEY    = "cFt6sZVPpt6hzIMiCvCnDA+Xi27At/+x";
const CONSUMER_SECRET = "GcLyvCpNUBd4DHsgFQjWrKbAPaQ=";

const axiosClient = axios.create({
    baseURL: 'https://pay.pesapal.com/v3/api',
    headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
});

const subscriptionsCol = "subscriptions";
const usersCol         = "users";

// PesaPal calls this via GET with OrderTrackingId + OrderMerchantReference as query params
const resolvePayment = onRequest(
    { cors: true },
    async (req, res) => {
        try {
            const db = getFirestore();
            const { OrderTrackingId, OrderMerchantReference } = req.query;

            if (!OrderTrackingId || !OrderMerchantReference) {
                return res.status(400).json({
                    error: { message: "Missing OrderTrackingId or OrderMerchantReference" }
                });
            }

            // Authenticate with PesaPal
            const authResp = await axiosClient.post("/Auth/RequestToken", {
                consumer_key: CONSUMER_KEY,
                consumer_secret: CONSUMER_SECRET,
            });
            const authData = authResp.data;
            if (authData.status != 200) {
                return res.json({ error: { message: "PesaPal auth failed" } });
            }
            const authKey = authData.token;

            // Get transaction status from PesaPal
            const transStatusResp = await axiosClient.get(
                `/Transactions/GetTransactionStatus?orderTrackingId=${OrderTrackingId}`,
                { headers: { Authorization: `Bearer ${authKey}` } }
            );
            const trans = transStatusResp.data;
            if (trans.status != 200) {
                return res.json({ error: { message: "Failed to fetch transaction status from PesaPal" } });
            }

            // Find the matching subscription record
            const subscriptionRef = db.collection(subscriptionsCol).doc(OrderMerchantReference);
            const subscriptionSnap = await subscriptionRef.get();
            if (!subscriptionSnap.exists) {
                return res.status(404).json({ error: { message: "Subscription record not found" } });
            }

            const subscription = subscriptionSnap.data();
            const isCompleted = trans.payment_status_description?.toLowerCase() === 'completed';
            const batch = db.batch();

            // Always update the subscription with latest PesaPal status
            batch.set(subscriptionRef, {
                payment_method: trans.payment_method,
                payment_amount: trans.amount,
                payment_status_description: trans.payment_status_description,
                message: trans.message,
                payment_account: trans.payment_account,
                merchant_reference: trans.merchant_reference,
                status: isCompleted ? "Completed" : trans.payment_status_description,
                updated_at: FieldValue.serverTimestamp(),
            }, { merge: true });

            // Payment succeeded — activate the user
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
                    activeSubscriptionId: OrderMerchantReference,
                }, { merge: true });
            }

            await batch.commit();

            return res.json({
                error: null,
                status: trans.payment_status_description,
                activated: isCompleted,
            });

        } catch (error) {
            console.error("resolvePayment error:", error);
            return res.status(500).json({ error: { message: error.message || String(error) } });
        }
    }
);

module.exports = { resolvePayment };
