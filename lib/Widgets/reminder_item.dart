import 'package:flutter/material.dart';

class ReminderItem extends StatelessWidget {
  final bool checked;
  final String medicine;
  final String time;
  final bool isLate;
  final ValueChanged<bool?>? onChanged;
  const ReminderItem({
    super.key,
    required this.checked,
    required this.medicine,
    required this.time,
    this.isLate = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            activeColor: const Color(0xFF4ACED0),
          ),
          Expanded(
            child: Text(
              medicine,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time + (isLate ? ' (LATE)' : ''),
            style: TextStyle(
              fontSize: 15,
              color: isLate ? const Color(0xFFE74C3C) : const Color(0xFF6B7280),
              fontWeight: isLate ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
