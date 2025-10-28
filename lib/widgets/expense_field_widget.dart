import 'package:flutter/material.dart';

class ExpenseFieldWidget extends StatelessWidget {
  final String categoryKey;
  final String displayName;
  final TextEditingController controller;
  final bool isReadOnly;
  final VoidCallback? onClear;
  final Function(String)? onChanged;

  const ExpenseFieldWidget({
    super.key,
    required this.categoryKey,
    required this.displayName,
    required this.controller,
    this.isReadOnly = false,
    this.onClear,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(displayName)),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              enabled: !isReadOnly,
              decoration: const InputDecoration(
                prefixText: '৳',
                hintText: '0',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onChanged: onChanged,
            ),
          ),
          if (!isReadOnly && onClear != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}
