const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json"); // you download this

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// load your JSON
const data = require("./Dosely medicines full.json");

async function uploadData() {
  console.log(`Starting upload of ${data.length} medicines...`);

  // Split into batches of 400 (Firestore limit is 500)
  const BATCH_SIZE = 400;

  for (let i = 0; i < data.length; i += BATCH_SIZE) {
    const chunk = data.slice(i, i + BATCH_SIZE);
    const batch = db.batch();

    for (const med of chunk) {
      const docRef = db.collection("medicines").doc(med.id);
      batch.set(docRef, med); // overwrites existing document
    }

    await batch.commit();
    console.log(`Uploaded ${Math.min(i + BATCH_SIZE, data.length)} / ${data.length}`);
  }

  console.log("All data uploaded!");
}

uploadData();