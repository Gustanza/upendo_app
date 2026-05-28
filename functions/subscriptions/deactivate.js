const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getFirestore } = require('firebase-admin/firestore');

// Runs daily at midnight UTC.
// Finds all users where isActive=true but subscriptionExpiry has passed,
// and sets isActive=false on each of them in batches.
const deactivateExpiredSubscriptions = onSchedule('0 0 * * *', async () => {
    const db  = getFirestore();
    const now = new Date();

    const snapshot = await db.collection('users')
        .where('isActive', '==', true)
        .where('subscriptionExpiry', '<=', now)
        .get();

    if (snapshot.empty) {
        console.log('deactivateExpired: no expired subscriptions found.');
        return;
    }

    // Firestore batches cap at 500 operations — chunk if needed
    const BATCH_LIMIT = 500;
    const docs = snapshot.docs;

    for (let i = 0; i < docs.length; i += BATCH_LIMIT) {
        const batch = db.batch();
        docs.slice(i, i + BATCH_LIMIT).forEach(doc => {
            batch.update(doc.ref, { isActive: false });
        });
        await batch.commit();
    }

    console.log(`deactivateExpired: deactivated ${docs.length} user(s).`);
});

module.exports = { deactivateExpiredSubscriptions };
