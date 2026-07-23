import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Destructive-action confirmation dialog (Cancel / Delete), shared by the
/// "delete one conversation" and "delete all conversations" flows.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            l10n.delete,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
