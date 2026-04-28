import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firebase_medicine_checker.dart';
import '../../services/medicine_service.dart';
import 'medicine_result_screen.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  static const _c1 = Color(0xFF48466E);
  static const _c2 = Color(0xFF3E84A8);
  static const _mint = Color(0xFFE0FBF4);

  File? _image;
  bool _processing = false;
  String _statusText = '';

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _statusText = '';
    });
  }

  Future<void> _analyze() async {
    final image = _image;
    if (image == null || _processing) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Please log in first.');
      return;
    }

    setState(() {
      _processing = true;
      _statusText = 'Reading text from image…';
    });

    try {
      final ocrText = await MedicineService.processImage(image.path);

      if (ocrText.trim().isEmpty) {
        _showError('No text found in the image. Try a clearer photo.');
        return;
      }

      if (!mounted) return;
      setState(() => _statusText = 'Checking against your health profile…');

      final result = await FirebaseMedicineChecker.checkMedicine(
        uid: user.uid,
        ocrText: ocrText,
      );

      if (!mounted) return;

      if (result == null) {
        _showError('No matching medicine found in the database.');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicineResultScreen(
            imagePath: image.path,
            ocrText: ocrText,
            medicineData: result,
          ),
        ),
      );
    } catch (e) {
      _showError('Analysis failed: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade400,
        content: Text(msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 1.0],
                colors: [_c1, _c2, Colors.white],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _circleBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          'Upload & Scan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Image preview / placeholder card
                        Expanded(
                          child: GestureDetector(
                            onTap: _processing ? null : _pickImage,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 24,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: _image != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.file(
                                            _image!,
                                            fit: BoxFit.cover,
                                          ),
                                          // Re-pick overlay
                                          if (!_processing)
                                            Positioned(
                                              right: 12,
                                              bottom: 12,
                                              child: GestureDetector(
                                                onTap: _pickImage,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.9),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.photo_library_rounded,
                                                    color: _c1,
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      )
                                    : _EmptyState(onTap: _pickImage),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Hint text
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _mint.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: _c2, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _image == null
                                      ? 'Tap the card above to choose a photo of a medicine label or box.'
                                      : 'Photo selected. Tap "Analyze" to check if it\'s safe for you.',
                                  style: const TextStyle(
                                    color: _c1,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Action buttons
                        Row(
                          children: [
                            // Change photo
                            if (_image != null) ...[
                              _OutlineBtn(
                                label: 'Change Photo',
                                icon: Icons.photo_library_rounded,
                                onTap: _processing ? null : _pickImage,
                              ),
                              const SizedBox(width: 12),
                            ],

                            // Analyze / upload
                            Expanded(
                              child: _PrimaryBtn(
                                label: _image == null
                                    ? 'Upload Photo'
                                    : 'Analyze',
                                icon: _image == null
                                    ? Icons.upload_rounded
                                    : Icons.biotech_rounded,
                                loading: _processing,
                                enabled: !_processing,
                                onTap: _image == null ? _pickImage : _analyze,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Full-screen processing overlay
          if (_processing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            color: _c2,
                            strokeWidth: 3.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Analyzing medicine',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _c1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_photo_alternate_rounded,
            size: 44,
            color: Color(0xFF4ACED0),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Upload a Medicine Photo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF48466E),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a photo of the medicine\nlabel, box, or packaging',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black45,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF48466E), Color(0xFF3E84A8)],
                )
              : null,
          color: enabled ? null : Colors.black12,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF4ACED0).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF48466E), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF48466E),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
