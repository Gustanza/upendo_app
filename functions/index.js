const { initializeApp } = require('firebase-admin/app');
const { setGlobalOptions } = require("firebase-functions");

initializeApp();
setGlobalOptions({ maxInstances: 10 });

const { subscribe }                      = require('./payments/index');
const { resolvePayment }                 = require('./payments/ipnresolver');
const { deactivateExpiredSubscriptions } = require('./subscriptions/deactivate');

exports.subscribe                      = subscribe;
exports.resolvePayment                 = resolvePayment;
exports.deactivateExpiredSubscriptions = deactivateExpiredSubscriptions;
