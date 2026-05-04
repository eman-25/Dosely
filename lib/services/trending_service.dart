import 'package:cloud_firestore/cloud_firestore.dart';

class TrendingService {
  static Future<List<String>> getTopTrendingNames() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('medication_events')
          .orderBy('timestamp', descending: true)
          .limit(200) // ✅ limit for performance
          .get();

      Map<String, int> counts = {};

      for (var doc in snapshot.docs) {
        String med = (doc['medication_name'] ?? '').toString();
        if (med.isNotEmpty) {
          counts[med] = (counts[med] ?? 0) + 1;
        }
      }

      var sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(5).map((e) => e.key).toList();
    } catch (e) {
      return [];
    }
  }
}