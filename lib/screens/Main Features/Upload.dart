import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/medicine_service.dart';
import '../../models/user_data.dart';
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
        SnackBar(content: Text('could_not_read'.tr())),
      );
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
      appBar: AppBar(title: Text('upload_photo'.tr())),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload, size: 120, color: Color(0xFF4ACED0)),
            const SizedBox(height: 24),
            Text(
              'select_medicine_photo'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _upload,
              icon: const Icon(Icons.photo_library),
              label: Text('choose_image'.tr()),
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