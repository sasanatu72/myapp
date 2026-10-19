import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/note_workspace_controller.dart';
import '../models/note.dart';
import '../models/note_content.dart';
import '../services/note_service.dart';
import '../utils/date_utils.dart';
import '../widgets/error_state.dart';
import '../widgets/note_document_editor.dart';
import 'settings_page.dart';

enum _NoteSort { updated, created, title }

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, this.note});

  final Note? note;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _search = TextEditingController();
  late final NoteWorkspaceController _workspace;
  _NoteSort _sort = _NoteSort.updated;
  bool _ascending = false;
  bool _overlayOpen = false;
  bool _drawerOpen = false;
  bool _canPop = false;
  bool _returning = false;

  @override
  void initState() {
    super.initState();
    _workspace = NoteWorkspaceController(context.read<NoteService>());
    _search.addListener(() => setState(() {}));
    Future.microtask(_loadWorkspace);
  }

  Future<void> _loadWorkspace() =>
      _workspace.load(initialNote: widget.note, createNew: widget.note == null);

  @override
  void dispose() {
    _search.dispose();
    _workspace.dispose();
    super.dispose();
  }

  Future<bool> prepareToLeave() async {
    final saved = await _workspace.flush();
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_workspace.error ?? '保存が完了するまでお待ちください。')),
      );
    }
    return saved;
  }

  Future<void> _returnToList() async {
    if (_returning) return;
    _returning = true;
    if (!await prepareToLeave() || !mounted) {
      _returning = false;
      return;
    }
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  Future<void> _select(Note? note) async {
    final selected = await _workspace.select(note);
    if (selected &&
        mounted &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _settings() async {
    if (!await prepareToLeave() || !mounted) return;
    setState(() => _overlayOpen = true);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
    if (mounted) setState(() => _overlayOpen = false);
  }

  Future<void> _delete() async {
    // A platform view must not receive pointer input behind a Flutter dialog.
    setState(() => _overlayOpen = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ノートを削除しますか？'),
        content: Text(
          '「${_workspace.title.trim().isEmpty ? '無題' : _workspace.title}」を削除します。',
        ),
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
      ),
    );
    if (!mounted) return;
    setState(() => _overlayOpen = false);
    if (confirmed == true) await _workspace.deleteSelected();
  }

  List<Note> get _visibleNotes {
    final query = _search.text.trim().toLowerCase();
    final notes = _workspace.notes.where((note) {
      final title = note.id == _workspace.selectedId
          ? _workspace.title
          : note.title;
      final content = note.id == _workspace.selectedId
          ? _workspace.content
          : note.content;
      return title.toLowerCase().contains(query) ||
          NoteContent.decode(content).text.toLowerCase().contains(query);
    }).toList();
    notes.sort((a, b) {
      final compare = switch (_sort) {
        _NoteSort.updated => a.updatedAt.compareTo(b.updatedAt),
        _NoteSort.created => a.createdAt.compareTo(b.createdAt),
        _NoteSort.title => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ),
      };
      if (compare == 0) return b.id.compareTo(a.id);
      return _ascending ? compare : -compare;
    });
    return notes;
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: _canPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _returnToList();
    },
    child: AnimatedBuilder(
      animation: _workspace,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final colors = Theme.of(context).colorScheme;
          return Scaffold(
            key: _scaffoldKey,
            onDrawerChanged: (open) => setState(() => _drawerOpen = open),
            appBar: AppBar(
              leading: IconButton(
                tooltip: '一覧に戻る',
                icon: const Icon(Icons.arrow_back),
                onPressed: _returnToList,
              ),
              title: const Text('ノート'),
              actions: [
                if (!wide)
                  IconButton(
                    tooltip: 'ノート一覧',
                    icon: const Icon(Icons.menu_book_outlined),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                _saveStatus(context, compact: !wide),
                IconButton(
                  tooltip: '今すぐ保存',
                  onPressed: _workspace.isSaving || !_workspace.isDirty
                      ? null
                      : prepareToLeave,
                  icon: const Icon(Icons.cloud_upload_outlined),
                ),
                IconButton(
                  tooltip: 'ノートを削除',
                  onPressed:
                      _workspace.selectedId == null || _workspace.isSwitching
                      ? null
                      : _delete,
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(
                  tooltip: '設定',
                  onPressed: _settings,
                  icon: const Icon(Icons.settings_outlined),
                ),
                const SizedBox(width: 8),
              ],
            ),
            drawer: wide ? null : Drawer(child: SafeArea(child: _sidebar())),
            body: SafeArea(
              child: _workspace.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _workspace.error != null && _workspace.editorVersion == 0
                  ? ErrorState(
                      message: _workspace.error!,
                      onRetry: _loadWorkspace,
                    )
                  : Row(
                      children: [
                        if (wide) ...[
                          SizedBox(width: 280, child: _sidebar()),
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: colors.outlineVariant,
                          ),
                        ],
                        Expanded(
                          child: Column(
                            children: [
                              if (_workspace.error != null) _saveError(context),
                              Expanded(
                                child: NoteDocumentEditor(
                                  key: ValueKey(_workspace.editorVersion),
                                  title: _workspace.title,
                                  content: _workspace.content,
                                  enabled:
                                      !_overlayOpen &&
                                      !_drawerOpen &&
                                      !_workspace.isSwitching,
                                  hasUnsavedChanges:
                                      _workspace.isDirty || _workspace.isSaving,
                                  onChanged: (title, content, composing) =>
                                      _workspace.change(
                                        title,
                                        content,
                                        composing: composing,
                                      ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: colors.outlineVariant,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '${NoteContent.decode(_workspace.content).text.characters.length} 文字 · 自動保存',
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    ),
  );

  Widget _saveStatus(BuildContext context, {bool compact = false}) {
    final label = _workspace.isSaving
        ? '保存中…'
        : _workspace.error != null
        ? '保存を確認'
        : _workspace.isComposing
        ? '変換中'
        : _workspace.isDirty
        ? '未保存'
        : '保存済み';
    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_workspace.isSaving)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _workspace.isDirty
                  ? Icons.cloud_queue
                  : Icons.cloud_done_outlined,
              size: 17,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _saveError(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.errorContainer,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_workspace.error!)),
        TextButton(onPressed: prepareToLeave, child: const Text('再試行')),
      ],
    ),
  );

  Widget _sidebar() {
    final colors = Theme.of(context).colorScheme;
    final notes = _visibleNotes;
    return ColoredBox(
      color: colors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: FilledButton.icon(
              onPressed: _workspace.isSwitching ? null : () => _select(null),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('新しいノート'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'ノートを検索',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '検索をクリア',
                        onPressed: _search.clear,
                        icon: const Icon(Icons.close, size: 18),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_workspace.notes.length} 件のノート',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                PopupMenuButton<_NoteSort>(
                  tooltip: '並び替え',
                  onSelected: (value) => setState(() {
                    _ascending = _sort == value
                        ? !_ascending
                        : value == _NoteSort.title;
                    _sort = value;
                  }),
                  itemBuilder: (_) => [
                    for (final item in {
                      _NoteSort.updated: '更新順',
                      _NoteSort.created: '作成順',
                      _NoteSort.title: 'タイトル順',
                    }.entries)
                      PopupMenuItem(
                        value: item.key,
                        child: Row(
                          children: [
                            Icon(
                              _sort == item.key
                                  ? (_ascending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                  : Icons.sort,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(item.value),
                          ],
                        ),
                      ),
                  ],
                  icon: const Icon(Icons.sort, size: 20),
                ),
              ],
            ),
          ),
          if (_workspace.selectedId == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListTile(
                selected: true,
                selectedTileColor: colors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: const Icon(Icons.edit_note),
                title: Text(
                  _workspace.title.trim().isEmpty ? '新しいノート' : _workspace.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('編集中の下書き'),
              ),
            ),
          Expanded(
            child: notes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _search.text.isEmpty
                          ? 'メモやアイデアを書き始めましょう。'
                          : '一致するノートがありません。',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      final selected = note.id == _workspace.selectedId;
                      final title = selected ? _workspace.title : note.title;
                      final text = NoteContent.decode(
                        selected ? _workspace.content : note.content,
                      ).text;
                      return ListTile(
                        selected: selected,
                        selectedTileColor: colors.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onTap: _workspace.isSwitching
                            ? null
                            : () => _select(note),
                        title: Text(
                          title.trim().isEmpty ? '無題' : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${text.trim().isEmpty ? '本文なし' : text.replaceAll('\n', ' ')}\n'
                          '${formatDateTime(note.updatedAt)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
