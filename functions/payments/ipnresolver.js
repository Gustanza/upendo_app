const axios = require('axios');
const { getFirestore } = require('firebase-admin/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { eventsCol, attendeesCol, attendeePaymentsCol } = require("../utils/constants");
const { FieldValue } = require("firebase-admin/firestore");

const axiosClient = axios.create({
    baseURL: 'https://pay.pesapal.com/v3/api',
    headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
});

const michangoPayCol = "michangoPayments";

const resolveMchango = onRequest(
    { cors: true },
    async (req, res) => {
        try {
            const db = getFirestore();
            const { OrderTrackingId, OrderMerchantReference } = req.query;
            const authResp = await axiosClient.post("/Auth/RequestToken", {
                "consumer_key": "cFt6sZVPpt6hzIMiCvCnDA+Xi27At/+x",
                "consumer_secret": "GcLyvCpNUBd4DHsgFQjWrKbAPaQ="
            });
            const authData = authResp.data;
            if (authData.status != 200) return res.json({
                error: {
                    message: "Auth failed"
                }
            });
            const authKey = authData.token;

            // Dealing Payment Resolution
            const transStatusResp = await axiosClient.get(`/Transactions/GetTransactionStatus?orderTrackingId=${OrderTrackingId}`, {
                headers: {
                    Authorization: `Bearer ${authKey}`
                }
            });

            const transStatusData = transStatusResp.data;
            if (authData.status != 200) return res.json({
                error: {
                    message: "Getting transaction from PesaPal failed"
                }
            });
            const paymentRef = db.collection(michangoPayCol).doc(OrderMerchantReference);
            const paymentSnapshot = await paymentRef.get();
            if (!paymentSnapshot.exists) return res.json({
                error: {
                    message: "Transaction record not found"
                }
            });

            const paymentMap = paymentSnapshot.data();
            const batch = db.batch();
            paymentMap.payment_method = transStatusData.payment_method;
            paymentMap.payment_amount = transStatusData.amount;
            paymentMap.payment_status_description = transStatusData.payment_status_description;
            paymentMap.message = transStatusData.message;
            paymentMap.payment_account = transStatusData.payment_account;
            paymentMap.merchant_reference = transStatusData.merchant_reference;
            paymentMap.updated_at = FieldValue.serverTimestamp();
            //
            batch.set(paymentRef, paymentMap, { merge: true })

            var attendeePayRef = db.collection(eventsCol)
                .doc(paymentMap.eventId)
                .collection(attendeesCol)
                .doc(paymentMap.attendeeId)
                .collection(attendeePaymentsCol)
                .doc(OrderMerchantReference)

            if (transStatusData.payment_status_description.toLowerCase() == 'completed')
                batch.set(attendeePayRef, {
                    amount: transStatusData.amount,
                    method: 'digital',
                    createdAt: new Date().toISOString(),
                }, { merge: true })

            await batch.commit()
            return res.json(transAction);
        } catch (error) {
            console.log(error)
            return res.json({ error: { message: error } });
        }
    });


module.exports = {
    resolveMchango: resolveMchango
};