import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/medicine_service.dart';
import '../../models/user_data.dart';
import 'package:provider/provider.dart';
import 'medicine_result_screen.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});
  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _upload() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final text = await MedicineService.processImage(file.path);
    final name = MedicineService.extractMedicineName(text);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read medicine name')));
      return;
    }

    final data = await MedicineService.fetchMedicineInfo(name);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicineResultScreen(
            medicineData: data,
            userData: Provider.of<UserData>(context, listen: false),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Photo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload, size: 120, color: Color(0xFF4ACED0)),
            const SizedBox(height: 24),
            const Text('Select medicine photo from gallery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _upload,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}