import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../providers/prefs_provider.dart';

/// Prompts for the SQLite database path, then persists it, reopens the database
/// and signals screens to reload. Returns true if the path was changed.
Future<bool> showDbPathDialog(BuildContext context, WidgetRef ref) async {
  final controller =
      TextEditingController(text: DatabaseService().currentPath);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.storage_rounded),
      title: const Text('Data source'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Full path to the expenses SQLite database file on this machine.'),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Database path',
              hintText: '/path/to/expenses.db',
              prefixIcon: Icon(Icons.folder_open, size: 18),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Apply')),
      ],
    ),
  );
  if (result == null) return false;
  final path = result.trim();
  ref.read(dbPathProvider.notifier).set(path);
  await DatabaseService().reopen(path);
  ref.read(dataReloadProvider.notifier).bump();
  return true;
}
