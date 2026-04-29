import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../services/note_service.dart';
import '../utils/date_utils.dart';
import '../widgets/app_page_container.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import 'note_editor_page.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final _searchController = TextEditingController();

  List<Note> _notes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    Future.microtask(_loadNotes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notes = await context.read<NoteService>().getNotes();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (!mounted) return;

      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }
  
  List<Note> get _filteredNotes {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _notes;

    return _notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openEditor({Note? note}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(note: note),
      ),
    );

    if (result == true) {
      await _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ノート'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return AppPageContainer(
        child: ErrorState(
          message: _errorMessage!,
          onRetry: _loadNotes,
        ),
      );
    }

    if (_notes.isEmpty) {
      return AppPageContainer(
        child: EmptyState(
          icon: Icons.note_add_outlined,
          title: 'ノートはまだありません',
          message: '右下の＋ボタンから、メモやアイデアを保存できます。',
          actionLabel: 'ノートを追加',
          onAction: () => _openEditor(),
        ),
      );
    }

    final filteredNotes = _filteredNotes;

    return AppPageContainer(
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'ノートを検索',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredNotes.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: '一致するノートがありません',
                    message: '別のキーワードで検索してください。',
                  )
                : ListView.separated(
                    itemCount: filteredNotes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return _NoteCard(
                        note: note,
                        onTap: () => _openEditor(note: note),
                        onDelete: () => _deleteNote(note),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(Note note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('ノートを削除しますか？'),
          content: Text('「${note.title}」を削除します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await context.read<NoteService>().deleteNote(note.id);
      await _loadNotes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final preview = note.content.trim().isEmpty ? '本文なし' : note.content;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.notes),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '更新: ${formatDateTime(note.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}