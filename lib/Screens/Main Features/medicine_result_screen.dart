import 'package:flutter/material.dart';
import '../../models/user_data.dart';
import 'Pill_Assistant_Home.dart';
class MedicineResultScreen extends StatelessWidget {
  final Map<String, dynamic> medicineData;
  final UserData userData;

  const MedicineResultScreen({super.key, required this.medicineData, required this.userData});

  bool get isSafe {
    final name = (medicineData['brand_name'] ?? '').toLowerCase();
    final allergies = userData.allergies.toLowerCase();
    final chronic = userData.chronicConditions.toLowerCase();

    if (allergies.contains('penicillin') && name.contains('amoxicillin')) return false;
    if (chronic.contains('liver') && name.contains('paracetamol')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final safe = isSafe;
    final color = safe ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: Text(medicineData['brand_name'] ?? 'Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
              child: Icon(safe ? Icons.verified : Icons.dangerous, size: 110, color: color),
            ),
            const SizedBox(height: 20),
            Text(safe ? 'SAFE TO USE' : 'NOT SAFE TO USE',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 30),

            Text(medicineData['purpose'] ?? 'Consult the label for full instructions',
                style: const TextStyle(fontSize: 16)),

            if (!safe) ...[
              const SizedBox(height: 20),
              const Text('⚠️ Reason based on your profile:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Allergy / Chronic condition match'),
            ],

            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Added to your schedule')));
                    },
                    child: const Text('Add to Schedule'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PillAssistantHome())),
                    child: const Text('Ask Pillo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}