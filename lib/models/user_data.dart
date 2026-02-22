// lib/models/user_data.dart
import 'package:flutter/material.dart';

class UserData extends ChangeNotifier {
  // Registration data
  String username = '';
  String email = '';
  String dob = '';
  String gender = '';
  String country = '';

  // Health Data
  String allergies = '';
  String chronicConditions = '';
  String currentMedications = '';
  String specialConditions = '';

  // Profile Picture (optional)
  ImageProvider<Object>? avatar;

  // IMPORTANT: This makes userData.name return the real username
  String get name => username.trim().isNotEmpty ? username.trim() : 'User';

  // Optional: alias for convenience
  String get fullName => username;

  void updateProfile({
    String? username,
    String? email,
    String? dob,
    String? gender,
    String? country,
    ImageProvider<Object>? avatar,
  }) {
    if (username != null) this.username = username;
    if (email != null) this.email = email;
    if (dob != null) this.dob = dob;
    if (gender != null) this.gender = gender;
    if (country != null) this.country = country;
    if (avatar != null) this.avatar = avatar;

    notifyListeners();
  }

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

  // Clear all data (useful for logout)
  void clear() {
    username = '';
    email = '';
    dob = '';
    gender = '';
    country = '';
    allergies = '';
    chronicConditions = '';
    currentMedications = '';
    specialConditions = '';
    avatar = null;
    notifyListeners();
  }
}