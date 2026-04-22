import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../services/firebase_medicine_checker.dart';
import 'medicine_result_screen.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _isTakingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _initializing = false;
      });

      _showError('Camera failed: $e');
    }
  }

  Future<void> _captureAndRead() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) return;
    if (_isTakingPhoto) return;

    setState(() {
      _isTakingPhoto = true;
    });

    try {
      final XFile file = await controller.takePicture();
      final imageFile = File(file.path);

      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      await textRecognizer.close();

      if (!mounted) return;

      final String ocrText = recognizedText.text.trim();

      if (ocrText.isEmpty) {
        _showError('No text detected from the image.');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('No logged in user found.');
        return;
      }

     final uid = FirebaseAuth.instance.currentUser!.uid;

    final medicineResult =
    await FirebaseMedicineChecker.checkMedicine(
      uid: uid,
      ocrText: ocrText,
    );

      if (!mounted) return;

      if (medicineResult == null) {
        _showError('No medicine match found in Firebase.');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicineResultScreen(
            imagePath: imageFile.path,
            ocrText: ocrText,
            medicineData: medicineResult,
          ),
        ),
      );
    } catch (e) {
      _showError('Scan failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPhoto = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_controller == null) {
      return const Scaffold(
        body: Center(
          child: Text('No camera available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Medicine'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Center the medicine name and dosage in the frame, then capture.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isTakingPhoto ? null : _captureAndRead,
        icon: _isTakingPhoto
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.camera_alt_rounded),
        label: Text(_isTakingPhoto ? 'Reading...' : 'Capture'),
        backgroundColor: const Color(0xFF3E84A8),
      ),
    );
  }
}