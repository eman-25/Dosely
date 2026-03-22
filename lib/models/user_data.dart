// lib/models/user_data.dart
import 'package:flutter/material.dart';

class UserData extends ChangeNotifier {
  // ── Basic Profile ──
  String username = '';
  String email = '';
  String dob = '';
  String gender = '';
  String country = '';
  String photoUrl = ''; // URL from Firestore (Firebase Storage upload)

  // ── Health Info ──
  String allergies = '';
  String chronicConditions = '';
  String currentMedications = '';
  String specialConditions = '';

  // ── Local avatar (for in-session picked image before upload) ──
  ImageProvider<Object>? avatar;

  // ── Getters ──
  String get name => username.trim().isNotEmpty ? username.trim() : 'User';
  String get fullName => username;

  // ─────────────────────────────────────────────
  // Called by UserService.loadUserIntoProvider()
  // after login — fills ALL fields from Firestore
  // ─────────────────────────────────────────────
  void loadFromFirestore({
    required String username,
    required String email,
    required String dob,
    required String gender,
    required String country,
    required String photoUrl,
    required String allergies,
    required String chronicConditions,
    required String currentMedications,
    required String specialConditions,
  }) {
    this.username = username;
    this.email = email;
    this.dob = dob;
    this.gender = gender;
    this.country = country;
    this.photoUrl = photoUrl;
    this.allergies = allergies;
    this.chronicConditions = chronicConditions;
    this.currentMedications = currentMedications;
    this.specialConditions = specialConditions;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Used by editprofile.dart (local update only —
  // actual Firestore write is in UserService)
  // ─────────────────────────────────────────────
  void updateProfile({
    String? username,
    String? email,
    String? dob,
    String? gender,
    String? country,
    String? photoUrl,
    ImageProvider<Object>? avatar,
  }) {
    if (username != null) this.username = username;
    if (email != null) this.email = email;
    if (dob != null) this.dob = dob;
    if (gender != null) this.gender = gender;
    if (country != null) this.country = country;
    if (photoUrl != null) this.photoUrl = photoUrl;
    if (avatar != null) this.avatar = avatar;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Used by personal_info_screen & edit health screen
  // ─────────────────────────────────────────────
  void updateHealthInfo({
    String? allergies,
    String? chronicConditions,
    String? currentMedications,
    String? specialConditions,
  }) {
    if (allergies != null) this.allergies = allergies;
    if (chronicConditions != null) this.chronicConditions = chronicConditions;
    if (currentMedications != null) this.currentMedications = currentMedications;
    if (specialConditions != null) this.specialConditions = specialConditions;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Called on logout
  // ─────────────────────────────────────────────
  void clear() {
    username = '';
    email = '';
    dob = '';
    gender = '';
    country = '';
    photoUrl = '';
    allergies = '';
    chronicConditions = '';
    currentMedications = '';
    specialConditions = '';
    avatar = null;
    notifyListeners();
  }
}