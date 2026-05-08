// ============================================================
//  medicine_model.dart
//  Typed data model — matches your exact Firestore schema.
//  No logic here, just data + serialisation.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineModel {
  final String id;
  final String name;
  final String genericName;
  final String dosage;
  final String description;
  final List<String> aliases;
  final List<String> avoidCombinations; // filled by RxNorm + OpenFDA
  final String allergyTrigger;          // filled by OpenFDA warnings
  final String pregnancyWarning;        // 'none' | 'caution' | 'avoid'

  // ── Internal cache metadata (not part of your public schema) ──────────────
  // Stored in Firestore but never exposed to UI.
  final String? rxcui;          // RxNorm concept ID — enables live interaction checks
  final DateTime? cachedAt;     // When this entry was last refreshed

  const MedicineModel({
    required this.id,
    required this.name,
    required this.genericName,
    required this.dosage,
    required this.description,
    required this.aliases,
    required this.avoidCombinations,
    required this.allergyTrigger,
    required this.pregnancyWarning,
    this.rxcui,
    this.cachedAt,
  });

  // ── Deserialise from Firestore ────────────────────────────────────────────
  factory MedicineModel.fromFirestore(Map<String, dynamic> d) {
    DateTime? cachedAt;
    if (d['_cached_at'] is Timestamp) {
      cachedAt = (d['_cached_at'] as Timestamp).toDate();
    }
    return MedicineModel(
      id: d['id'] ?? '',
      name: d['name'] ?? '',
      genericName: d['generic_name'] ?? '',
      dosage: d['dosage'] ?? '',
      description: d['description'] ?? '',
      aliases: List<String>.from(d['aliases'] ?? []),
      avoidCombinations: List<String>.from(d['avoid_combinations'] ?? []),
      allergyTrigger: d['allergy_trigger'] ?? '',
      pregnancyWarning: d['pregnancy_warning'] ?? 'none',
      rxcui: d['_rxcui'] as String?,
      cachedAt: cachedAt,
    );
  }

  // ── Serialise to Firestore ────────────────────────────────────────────────
  // Public fields use YOUR exact schema keys.
  // Internal fields are prefixed with _ so they are easy to strip in queries.
  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'generic_name': genericName,
        'dosage': dosage,
        'description': description,
        'aliases': aliases,
        'avoid_combinations': avoidCombinations,
        'allergy_trigger': allergyTrigger,
        'pregnancy_warning': pregnancyWarning,
        '_rxcui': rxcui ?? '',
        '_cached_at': FieldValue.serverTimestamp(),
      };

  // ── Return a copy with updated fields ────────────────────────────────────
  MedicineModel copyWith({
    String? rxcui,
    List<String>? avoidCombinations,
    String? allergyTrigger,
    String? pregnancyWarning,
  }) =>
      MedicineModel(
        id: id,
        name: name,
        genericName: genericName,
        dosage: dosage,
        description: description,
        aliases: aliases,
        avoidCombinations: avoidCombinations ?? this.avoidCombinations,
        allergyTrigger: allergyTrigger ?? this.allergyTrigger,
        pregnancyWarning: pregnancyWarning ?? this.pregnancyWarning,
        rxcui: rxcui ?? this.rxcui,
        cachedAt: cachedAt,
      );

  // ── Cache freshness ───────────────────────────────────────────────────────
  // Re-fetch from APIs if the cached entry is older than 30 days.
  bool get isStale {
    if (cachedAt == null) return true;
    return DateTime.now().difference(cachedAt!).inDays > 30;
  }
}