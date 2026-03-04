import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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
            const SizedBox(height: 20),
            CustomTextField(
              hint: 'describe_problem'.tr(),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('attach_coming_soon'.tr())),
                    );
                  },
                  child: Text('attach_screenshot'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'submit_report'.tr(),
              onPressed: () {
                if (_descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('describe_issue_prompt'.tr())),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('report_submitted'.tr()),
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