import 'dart:typed_data';

import 'package:flutter/material.dart';

class FilePickerField extends StatelessWidget {
  const FilePickerField({
    super.key,
    required this.label,
    required this.onPick,
    this.previewText,
    this.progress,
    this.enabled = true,
  });

  final String label;
  final Future<void> Function() onPick;
  final String? previewText;
  final double? progress; // 0..1
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: enabled ? onPick : null,
          icon: const Icon(Icons.upload_file),
          label: Text(label),
        ),
        if (previewText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(previewText!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        if (progress != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(value: progress!.clamp(0.0, 1.0)),
          ),
      ],
    );
  }
}


