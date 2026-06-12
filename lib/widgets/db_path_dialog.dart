import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../providers/prefs_provider.dart';

/// Prompts for the SQLite database file (native picker, with the path still
/// editable by hand), then persists it, reopens the database and signals
/// screens to reload. Returns true if the path was changed.
Future<bool> showDbPathDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => const _DbPathDialog(),
  );
  if (result == null) return false;
  final path = result.trim();
  ref.read(dbPathProvider.notifier).set(path);
  await DatabaseService().reopen(path);
  ref.read(dataReloadProvider.notifier).bump();
  return true;
}

class _DbPathDialog extends StatefulWidget {
  const _DbPathDialog();

  @override
  State<_DbPathDialog> createState() => _DbPathDialogState();
}

class _DbPathDialogState extends State<_DbPathDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: DatabaseService().currentPath ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _browse() async {
    const typeGroup = XTypeGroup(
      label: 'SQLite database',
      extensions: ['db', 'sqlite', 'sqlite3'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file != null && mounted) {
      setState(() => _controller.text = file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.storage_rounded),
      title: const Text('Data source'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'The SQLite database file containing your expenses table.'),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Database path',
                hintText: '/path/to/expenses.db',
                prefixIcon: Icon(Icons.folder_open, size: 18),
              ),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _browse,
                icon: const Icon(Icons.file_open_outlined, size: 18),
                label: const Text('Browse…'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: const Text('Apply')),
      ],
    );
  }
}
