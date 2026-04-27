import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_data.dart';
import '../../Widgets/custom_button.dart';
import '../../Widgets/custom_textfield.dart';
import '/theme.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _descriptionController = TextEditingController();
  final _suggestionController = TextEditingController();

  String? _selectedIssueType;
  File? _attachedFile;

  double _rating = 0;

  @override
  void dispose() {
    _descriptionController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _attachedFile = File(picked.path));
    }
  }

  Future<void> _sendReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('describe_issue_prompt'.tr())),
      );
      return;
    }

    final user = Provider.of<UserData>(context, listen: false);
    final issueType = _selectedIssueType ?? 'Other';
    final userEmail = user.email.isNotEmpty ? user.email : 'Unknown User';

    final description = _descriptionController.text.trim();
    final suggestion = _suggestionController.text.trim();

    /// 🔥 SAVE TO FIREBASE (for dashboard)
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        "user": userEmail,
        "issue_type": issueType,
        "rating": _rating,
        "description": description,
        "suggestion": suggestion,
        "timestamp": DateTime.now(),
      });
    } catch (e) {
      debugPrint("Firestore error: $e");
    }

    /// 📧 EMAIL BODY
    final body = '''
Reported by: $userEmail
Issue Type: $issueType
Rating: $_rating / 5

Description:
$description

Suggestions:
$suggestion
''';

    final Email email = Email(
      body: body,
      subject: 'Dosely Support Request: $issueType',
      recipients: ['doselysupport@gmail.com'],
      attachmentPaths: _attachedFile != null ? [_attachedFile!.path] : null,
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('report_submitted'.tr()),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Could not open email client. $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> issueTypes = [
      'issue_crashes'.tr(),
      'issue_medication'.tr(),
      'issue_login'.tr(),
      'issue_notifications'.tr(),
      'issue_ui'.tr(),
      'issue_other'.tr(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text('report_problem'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// TITLE
            Text(
              'report_problem_title'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'report_problem_subtitle'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            /// ISSUE TYPE
            DropdownButtonFormField<String>(
              value: _selectedIssueType,
              hint: Text('select_issue_type'.tr()),
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: issueTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedIssueType = value),
            ),

            /// ⭐ RATING
            const SizedBox(height: 20),
            const Text(
              "Rate your experience",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),

            Text("Your Rating: $_rating / 5"),

            /// DESCRIPTION
            const SizedBox(height: 20),
            CustomTextField(
              hint: 'describe_problem'.tr(),
              controller: _descriptionController,
              maxLines: 5,
            ),

            /// SUGGESTIONS
            const SizedBox(height: 20),
            const Text(
              "Suggestions for improvement",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            CustomTextField(
              hint: "Tell us how we can improve...",
              controller: _suggestionController,
              maxLines: 3,
            ),

            /// ATTACH IMAGE
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.attach_file, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _pickImage,
                  child: Text(
                    _attachedFile != null
                        ? 'Image Attached'
                        : 'attach_screenshot'.tr(),
                  ),
                ),
                if (_attachedFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => setState(() => _attachedFile = null),
                  ),
              ],
            ),

            const SizedBox(height: 32),

            /// SUBMIT
            CustomButton(
              text: 'submit_report'.tr(),
              onPressed: _sendReport,
            ),
          ],
        ),
      ),
    );
  }
}