const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.updateTrending = functions.firestore
    .document("medication_events/{id}")
    .onCreate(async (snap, context) => {
      const data = snap.data();
      const med = data.medication_name;

      if (!med) return null;

      const ref = admin.firestore()
          .collection("trending_medications")
          .doc(med);

      await admin.firestore().runTransaction(async (t) => {
        const doc = await t.get(ref);

        if (!doc.exists) {
          t.set(ref, {
            count: 1,
            last_updated: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          t.update(ref, {
            count: doc.data().count + 1,
            last_updated: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });

      return null;
    });
