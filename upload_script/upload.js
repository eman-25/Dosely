const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json"); // you download this

admin.initializeApp({
credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// load your JSON
const data = require("./medications_full_clean.json");

async function uploadData() {
for (const med of data) {
    await db.collection("medicines").doc(med.id).set(med);
    console.log(`Uploaded: ${med.id}`);
}
console.log("All data uploaded!");
}

uploadData();