// lib/screens/report_problem.dart
import 'package:flutter/material.dart';
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
  String? _selectedIssueType;

  final List<String> _issueTypes = [
    'App crashes or freezes',
    'Wrong medication suggestion',
    'Login / account problem',
    'Notifications not working',
    'UI / design issue',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Report a Problem'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us improve Dosely',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please describe the issue you are facing. The more details you provide, the faster we can help.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              initialValue: _selectedIssueType,
              hint: const Text('Select issue type'),
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _issueTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedIssueType = value),
            ),
            const SizedBox(height: 20),

            CustomTextField(
              hint: 'Describe the problem in detail...',
              controller: _descriptionController,
              maxLines: 5,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.attach_file, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    // TODO: image picker / file upload
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Attach screenshot coming soon')),
                    );
                  },
                  child: const Text('Attach screenshot (optional)'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            CustomButton(
              text: 'Submit Report',
              onPressed: () {
                if (_descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please describe the issue')),
                  );
                  return;
                }

                // TODO: send to backend / Firebase / email
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you! Your report has been submitted.'),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}