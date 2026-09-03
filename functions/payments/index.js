const axios = require('axios');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onRequest } = require('firebase-functions/v2/https');

const CONSUMER_KEY = "vNdwWW80VuOrkiozwtGoI0SFJb+oRuDk";
const CONSUMER_SECRET = "JGmtvImHCX1t29RP/RmrWlGiz58=";

// Update this after first deploy — grab the resolvePayment URL from Firebase console
const RESOLVE_PAYMENT_URL = "https://resolvepayment-dcnp2gn42a-uc.a.run.app";

const axiosClient = axios.create({
    baseURL: 'https://pay.pesapal.com/v3/api',
    headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
});

const packagesCol = "packages";
const subscriptionsCol = "subscriptions";
const usersCol = "users";

const subscribe = onRequest(
    { cors: true },
    async (req, res) => {
        try {
            const db = getFirestore();
            const { userId, packageId, callback_url } = req.body;

            if (!userId || !packageId || !callback_url) {
                return res.status(400).json({
                    error: { message: "userId, packageId, and callback_url are required" }
                });
            }

            // Fetch subscription package
            const packageDoc = await db.collection(packagesCol).doc(packageId).get();
            if (!packageDoc.exists) {
                return res.status(404).json({ error: { message: "Package not found" } });
            }
            const pkg = packageDoc.data();

            if (!pkg.isActive) {
                return res.status(400).json({ error: { message: "Package is not available" } });
            }

            // Fetch user for billing info
            const userDoc = await db.collection(usersCol).doc(userId).get();
            if (!userDoc.exists) {
                return res.status(404).json({ error: { message: "User not found" } });
            }
            const user = userDoc.data();

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

            // Register IPN endpoint
            const ipnResp = await axiosClient.post('/URLSetup/RegisterIPN', {
                url: RESOLVE_PAYMENT_URL,
                ipn_notification_type: "GET",
            }, {
                headers: { Authorization: `Bearer ${authKey}` }
            });
            const ipnData = ipnResp.data;
            if (ipnData.status != 200) {
                return res.json({ error: { message: "IPN registration failed" } });
            }
            const ipn_id = ipnData.ipn_id;

            // Create the subscription record first so we have its ID as the order ID
            const subscriptionRef = db.collection(subscriptionsCol).doc();

            // Submit order to PesaPal
            const orderResp = await axiosClient.post("/Transactions/SubmitOrderRequest", {
                id: subscriptionRef.id,
                currency: pkg.currency || "TZS",
                amount: pkg.price,
                description: `${pkg.name} - Nguvu ya Upendo`,
                callback_url: callback_url,
                redirect_mode: "",
                notification_id: ipn_id,
                branch: "NGUVU YA UPENDO",
                billing_address: {
                    email_address: user.email || "",
                    phone_number: user.phone || "",
                    country_code: "TZ",
                    first_name: user.fullName || "User",
                    middle_name: "",
                    last_name: "",
                    line_1: "",
                    line_2: "",
                    city: "",
                    state: "",
                    postal_code: "",
                    zip_code: "",
                },
            }, {
                headers: { Authorization: `Bearer ${authKey}` }
            });

            const orderData = orderResp.data;
            if (orderData.status != 200) {
                return res.json({ error: { message: orderData.error || "Order submission failed" } });
            }

            // Persist pending subscription record
            await subscriptionRef.set({
                userId,
                packageId,
                packageName: pkg.name,
                durationDays: pkg.durationDays,
                amount: pkg.price,
                currency: pkg.currency || "TZS",
                order_tracking_id: orderData.order_tracking_id,
                merchant_reference: orderData.merchant_reference,
                redirect_url: orderData.redirect_url,
                status: "PENDING",
                created_at: FieldValue.serverTimestamp(),
            });

            return res.json({
                error: null,
                redirect_url: orderData.redirect_url,
                order_tracking_id: orderData.order_tracking_id,
                merchant_reference: orderData.merchant_reference,
                subscription_id: subscriptionRef.id,
            });

        } catch (error) {
            console.error("subscribe error:", error);
            return res.status(500).json({ error: { message: error.message || String(error) } });
        }
    }
);

module.exports = { subscribe };
