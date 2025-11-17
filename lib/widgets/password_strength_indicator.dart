import 'package:flutter/material.dart';
import '../utils/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final int strength;
  final String feedback;

  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 5,
                backgroundColor: Colors.grey.shade200,
                color: Validators.getPasswordStrengthColor(strength),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              Validators.getPasswordStrengthLabel(strength),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Validators.getPasswordStrengthColor(strength),
              ),
            ),
          ],
        ),
        if (feedback.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              feedback,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Requirements: 8+ chars, uppercase, lowercase, number, special char (@\$!%*?&)',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
