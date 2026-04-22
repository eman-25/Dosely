import 'dart:convert';
import 'package:http/http.dart' as http;

class MedicineApiService {
  // CHANGE THIS depending on how you run Flutter:
  //
  // Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:8000';
  //
  // Real Android phone on same Wi-Fi as laptop:
  // static const String baseUrl = 'http://192.168.1.5:8000';
  //
  // Chrome/Web:
  // static const String baseUrl = 'http://127.0.0.1:8000';

  static const String baseUrl = 'http://192.168.1.5:8000';

  static Future<Map<String, dynamic>?> predictMedicine(String ocrText) async {
    final url = Uri.parse('$baseUrl/predict');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ocr_text': ocrText,
          'top_k': 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'] != null &&
            data['results'] is List &&
            data['results'].isNotEmpty) {
          return Map<String, dynamic>.from(data['results'][0]);
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }
}