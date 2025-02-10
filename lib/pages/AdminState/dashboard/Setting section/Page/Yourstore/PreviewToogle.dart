// lib/widgets/admin/preview_toggle.dart
import 'package:flutter/material.dart';

class PreviewToggle extends StatelessWidget {
  final bool isPreviewMode;
  final VoidCallback onToggle;

  const PreviewToggle({
    super.key,
    required this.isPreviewMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          isPreviewMode ? 'Exit Preview' : 'Preview Store',
          style: TextStyle(
            color: isPreviewMode ? Colors.blue : Colors.grey,
          ),
        ),
        Switch(
          value: isPreviewMode,
          onChanged: (_) => onToggle(),
        ),
      ],
    );
  }
}
