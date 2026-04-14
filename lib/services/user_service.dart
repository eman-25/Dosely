import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_data.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────
  // GET current user's Firestore document ref
  // ─────────────────────────────────────────────
  static DocumentReference get _userDoc =>
      _db.collection('users').doc(_auth.currentUser!.uid);

  // ─────────────────────────────────────────────
  // STEP 1 — Called after Firebase Auth signup
  // Saves basic profile (register_screen.dart)
  // ─────────────────────────────────────────────
  static Future<void> saveBasicProfile({
    required String username,
    required String email,
    required String dob,
    required String gender,
    required String country,
  }) async {
    await _userDoc.set({
      'uid': _auth.currentUser!.uid,
      'username': username,
      'email': email,
      'dob': dob,
      'gender': gender,
      'country': country,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────
  // STEP 2 — Called after personalization screen
  // Saves health info (personal_info_screen.dart)
  // ─────────────────────────────────────────────
  static Future<void> saveHealthInfo({
    required String allergies,
    required String chronicConditions,
    required String currentMedications,
    required String specialConditions,
  }) async {
    await _userDoc.set({
      'healthInfo': {
        'allergies': allergies,
        'chronicConditions': chronicConditions,
        'currentMedications': currentMedications,
        'specialConditions': specialConditions,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────
  // Called when user edits profile (editprofile.dart)
  // ─────────────────────────────────────────────
  static Future<void> updateProfile({
    required String username,
    required String email,
    required String dob,
    required String gender,
    required String country,
    String? photoUrl, // pass if you upload to Firebase Storage
  }) async {
    final data = {
      'username': username,
      'email': email,
      'dob': dob,
      'gender': gender,
      'country': country,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    await _userDoc.update(data);
  }

  // ─────────────────────────────────────────────
  // Called when user edits health info
  // (edit_personalhealthinfo.dart)
  // ─────────────────────────────────────────────
  static Future<void> updateHealthInfo({
    required String allergies,
    required String chronicConditions,
    required String currentMedications,
    required String specialConditions,
  }) async {
    await _userDoc.update({
      'healthInfo': {
        'allergies': allergies,
        'chronicConditions': chronicConditions,
        'currentMedications': currentMedications,
        'specialConditions': specialConditions,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  // ─────────────────────────────────────────────
  // Called at login — loads all data into UserData
  // ─────────────────────────────────────────────
  static Future<void> loadUserIntoProvider(UserData userData) async {
    final doc = await _userDoc.get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final health = data['healthInfo'] as Map<String, dynamic>? ?? {};

    userData.loadFromFirestore(
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      dob: data['dob'] ?? '',
      gender: data['gender'] ?? '',
      country: data['country'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      allergies: health['allergies'] ?? '',
      chronicConditions: health['chronicConditions'] ?? '',
      currentMedications: health['currentMedications'] ?? '',
      specialConditions: health['specialConditions'] ?? '',
    );
  }
}