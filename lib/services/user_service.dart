import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> saveUserProfile({
  required String fullName,
  required Map<String, dynamic> healthInfo,
}) async {
  final user = FirebaseAuth.instance.currentUser!;
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .set({
    'fullName': fullName,
    'email': user.email,
    'emailVerified': user.emailVerified,
    'healthInfo': healthInfo,
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}