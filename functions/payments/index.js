const axios = require('axios');
const { getFirestore } = require('firebase-admin/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { eventsCol, attendeesCol, attendeePaymentsCol } = require("../utils/constants");
const { FieldValue } = require("firebase-admin/firestore");
const {
    onDocumentWritten,
} = require('firebase-functions/v2/firestore');


const axiosClient = axios.create({
    baseURL: 'https://pay.pesapal.com/v3/api',
    headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
});

const paymentsCol = "payments";

const lipaMchango = onRequest(
    { cors: true },
    async (req, res) => {
        try {
            const db = getFirestore();
            var body = req.body;
            const amount = body.amount;
            const userId = body.userId;
            const callback_url = body.callback_url;
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
            const ipnResp = await axiosClient.post('/URLSetup/RegisterIPN', {
                "url": "https://resolvemchango-frbu33fema-uc.a.run.app",
                "ipn_notification_type": "GET"
            }, {
                headers: {
                    Authorization: `Bearer ${authKey}`
                }
            });
            const ipnData = ipnResp.data;
            if (ipnData.status != 200) return res.json({
                error: {
                    message: "IPN Registration failed"
                }
            });
            const ipn_id = ipnData.ipn_id;
            console.log("IPN Here: ", callback_url);
            // Constructing Submit Order
            const paymentRef = db.collection(paymentsCol).doc();
            const orderReqResp = await axiosClient.post("/Transactions/SubmitOrderRequest", {
                "id": paymentRef.id,
                "currency": "TZS",
                "amount": amount,
                "description": "Payment description goes here",
                "callback_url": callback_url,
                "redirect_mode": "",
                "notification_id": ipn_id,
                "branch": "HAFLAWAY SPA",
                "billing_address": {
                    "email_address": "haflaway@gmail.com",
                    "phone_number": attendee.phone,
                    "country_code": "TZ",
                    "first_name": attendee.fullName,
                    "middle_name": "",
                    "last_name": "Doe",
                    "line_1": "Pesapal Limited",
                    "line_2": "",
                    "city": "",
                    "state": "",
                    "postal_code": "",
                    "zip_code": ""
                },
            }, {
                headers: {
                    Authorization: `Bearer ${authKey}`
                }
            }
            );
            var orderReqRespData = orderReqResp.data
            if (orderReqRespData.status != 200) return res.json({
                error: {
                    message: orderReqRespData.error
                }
            });
            var trnObject = {
                "order_tracking_id": orderReqRespData.order_tracking_id,
                "merchant_reference": orderReqRespData.merchant_reference,
                "eventId": userId,
                "attendeeId": attendee.id,
                "expected_amount": amount,
                "redirect_url": orderReqRespData.redirect_url,
                "payment_status_description": "INVOKED",
                created_at: FieldValue.serverTimestamp()
            }
            await paymentRef.set(trnObject);
            trnObject.error = null;
            return res.json(trnObject);
        } catch (error) {
            return res.json({ error: { message: error } });
        }
    });


const recalculateUserPaid = onDocumentWritten(`${eventsCol}/{eventId}/${attendeesCol}/{attendeeId}/${attendeePaymentsCol}/{paymentId}`,
    async (event) => {
        try {
            const eventId = event.params.eventId;
            const attendeeId = event.params.attendeeId;
            const db = getFirestore();
            var attPaysSnap = await db.collection(eventsCol)
                .doc(eventId)
                .collection(attendeesCol)
                .doc(attendeeId)
                .collection(attendeePaymentsCol)
                .get();

            if (attPaysSnap.empty)
                console.log("Shida: Attendee hana payments");

            let totalPay = 0.0;

            attPaysSnap.forEach(doc => {
                const payData = doc.data();
                totalPay += payData.amount ?? 0.0;
            });

            await db.collection(eventsCol)
                .doc(eventId)
                .collection(attendeesCol)
                .doc(attendeeId).set({
                    paidAmount: totalPay
                }, { merge: true });

        } catch (error) {
            return console.log("Shida: ", error);
        }
        // perform more operations ...
    });


module.exports = {
    lipaMchango,
    recalculateUserPaid
};