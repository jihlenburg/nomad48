import 'package:flutter/material.dart';

/// Shared helpers used by multiple device card widgets.

String unknownLabel(String remoteId) {
  final clean = remoteId.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
  final suffix = clean.length >= 4
      ? clean.substring(clean.length - 4).toUpperCase()
      : clean.toUpperCase();
  return 'Unknown ($suffix)';
}

TextStyle detailStyle(BuildContext context) => TextStyle(
    fontSize: 12,
    color: Theme.of(context).colorScheme.onSurface.withAlpha(130));
