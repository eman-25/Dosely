import 'dart:io';
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

  File? _pickedImage;   // ← holds the preview image
  bool _isLoading = false;

  // Step 1: just pick the image and show preview
  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _pickedImage = File(file.path);
    });
  }

  // Step 2: user pressed "Upload Image" — now process and go to results
  Future<void> _processImage() async {
    if (_pickedImage == null) return;
    setState(() => _isLoading = true);

    try {
      final text = await MedicineService.processImage(_pickedImage!.path);
      final name = MedicineService.extractMedicineName(text);

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('could_not_read'.tr())),
        );
        setState(() => _isLoading = false);
        return;
      }

      final data = await MedicineService.fetchMedicineInfo(name);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineResultScreen(
              medicineData: data,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('could_not_read'.tr())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('upload_photo'.tr())),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Show preview if image picked, else show placeholder ──
              GestureDetector(
                onTap: _pickImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF4ACED0),
                      width: 2,
                    ),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.file(
                            _pickedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload,
                                size: 80, color: Color(0xFF4ACED0)),
                            const SizedBox(height: 16),
                            Text(
                              'select_medicine_photo'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // ── If no image: "Choose Image" button ──
              // ── If image picked: "Upload Image" button ──
              if (_pickedImage == null)
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: Text('choose_image'.tr()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                )
              else
                Column(
                  children: [
                    // Upload Image button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _processImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ACED0),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'upload_image'.tr(),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Change image link
                    TextButton(
                      onPressed: _pickImage,
                      child: Text(
                        'choose_image'.tr(),
                        style: const TextStyle(color: Color(0xFF4ACED0)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
