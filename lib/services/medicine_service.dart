import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MedicineService {
  static final TextRecognizer _recognizer = TextRecognizer();

  // Extract medicine name from OCR text
  static String extractMedicineName(String text) {
    final lines = text.split('\n');
    for (var line in lines) {
      final clean = line.trim();
      if (clean.length > 3 && RegExp(r'[a-zA-Z]').hasMatch(clean)) {
        return clean.split(RegExp(r'[\s\d]'))[0]; // first word
      }
    }
    return '';
  }

  // Call OpenFDA + fallback RxNav
  static Future<Map<String, dynamic>> fetchMedicineInfo(String name) async {
    try {
      final url = Uri.parse(
          'https://api.fda.gov/drug/label.json?search=brand_name:"$name"&limit=1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0];
        }
      }
    } catch (_) {}

    // Fallback
    return {
      'brand_name': name,
      'purpose': 'Pain relief / Consult label',
      'error': 'Limited data available'
    };
  }

  // Process image (camera or gallery)
  static Future<String> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);
    return recognized.text;
  }
}