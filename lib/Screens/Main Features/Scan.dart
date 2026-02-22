import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/medicine_service.dart';
import '../../models/user_data.dart';
import '../../Widgets/custom_textfield.dart';
import '../../Widgets/custom_button.dart';
import '/theme.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'medicine_result_screen.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});
  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  CameraController? _controller;
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    _initFuture = _controller!.initialize();
    setState(() {});
  }

  Future<void> _scan() async {
    try {
      await _initFuture;
      final image = await _controller!.takePicture();
      final text = await MedicineService.processImage(image.path);
      final name = MedicineService.extractMedicineName(text);

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read medicine name')),
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
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Medicine')),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller!),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: FloatingActionButton.large(
                      onPressed: _scan,
                      child: const Icon(Icons.camera_alt, size: 40),
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
