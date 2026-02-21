// lib/models/user_data.dart
import 'package:flutter/material.dart';

class UserData extends ChangeNotifier {
  String username = '';
  String email = '';
  String dob = '';
  String gender = '';
  String country = '';

  // Health Data (comes from Personal Info screen)
  String allergies = '';
  String chronicConditions = '';
  String currentMedications = '';
  String specialConditions = '';

  void updateProfile({
    String? username,
    String? email,
    String? dob,
    String? gender,
    String? country,
  }) {
    if (username != null) this.username = username;
    if (email != null) this.email = email;
    if (dob != null) this.dob = dob;
    if (gender != null) this.gender = gender;
    if (country != null) this.country = country;
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
}