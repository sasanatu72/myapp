import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../models/note_content.dart';
import '../services/note_service.dart';

class NoteWorkspaceController extends ChangeNotifier {
  NoteWorkspaceController(this.service);

  final NoteService service;
  final List<Note> _notes = [];
  List<Note> get notes => List.unmodifiable(_notes);
  bool isLoading = true;
  bool isSaving = false;
  bool isSwitching = false;
  bool isComposing = false;
  String? error;
  int? selectedId;
  int editorVersion = 0;
  String title = '';
  String content = '';
  int _revision = 0;
  int _savedRevision = 0;
  Timer? _timer;
  Future<bool>? _pendingSave;
  bool _disposed = false;

  bool get isDirty => _revision != _savedRevision && !_emptyNewNote;
  bool get _emptyNewNote =>
      selectedId == null &&
      title.trim().isEmpty &&
      NoteContent.decode(content).text.trim().isEmpty;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({Note? initialNote, bool createNew = false}) async {
    isLoading = true;
    error = null;
    _emit();
    try {
      final result = await service.getNotes();
      if (_disposed) return;
      _notes
        ..clear()
        ..addAll(result);
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _open(
        createNew
            ? null
            : initialNote == null
            ? (_notes.isEmpty ? null : _notes.first)
            : _notes.firstWhere(
                (note) => note.id == initialNote.id,
                orElse: () => initialNote,
              ),
      );
    } catch (e) {
      error = _message(e);
    } finally {
      isLoading = false;
      _emit();
    }
  }

  void change(String newTitle, String newContent, {required bool composing}) {
    if (_disposed) return;
    isComposing = composing;
    if (newTitle != title || newContent != content) {
      title = newTitle;
      content = newContent;
      _revision++;
      error = null;
    }
    _timer?.cancel();
    if (!composing && isDirty) {
      _timer = Timer(const Duration(milliseconds: 900), flush);
    }
    _emit();
  }

  /// Serialize writes and drain edits made while a request was in flight.
  Future<bool> flush() async {
    _timer?.cancel();
    if (_pendingSave != null) {
      final success = await _pendingSave!;
      if (!success || _disposed) return success;
      return flush();
    }
    if (!isDirty || _disposed) return true;
    if (isComposing) {
      error = '日本語の変換を確定してから移動してください。';
      _emit();
      return false;
    }
    final future = _saveChanges();
    _pendingSave = future;
    final success = await future;
    _pendingSave = null;
    return success;
  }

  Future<bool> _saveChanges() async {
    isSaving = true;
    error = null;
    _emit();
    try {
      while (isDirty && !isComposing && !_disposed) {
        final revision = _revision;
        final snapshotTitle = title.trim().isEmpty ? '無題' : title.trim();
        final snapshotContent = content;
        final note = selectedId == null
            ? await service.createNote(
                title: snapshotTitle,
                content: snapshotContent,
              )
            : await service.updateNote(
                id: selectedId!,
                title: snapshotTitle,
                content: snapshotContent,
              );
        if (_disposed) return false;
        selectedId = note.id;
        _savedRevision = revision;
        final index = _notes.indexWhere((item) => item.id == note.id);
        if (index < 0) {
          _notes.insert(0, note);
        } else {
          _notes[index] = note;
        }
        // Never replace the live editor DOM or selection with a save response.
        _emit();
      }
      return !isDirty;
    } catch (e) {
      error = _message(e);
      return false;
    } finally {
      isSaving = false;
      _emit();
    }
  }

  Future<bool> select(Note? note) async {
    if (isSwitching) return false;
    if (note != null && note.id == selectedId) return true;
    isSwitching = true;
    _emit();
    try {
      if (!await flush() || _disposed) return false;
      _open(note);
      return true;
    } finally {
      isSwitching = false;
      _emit();
    }
  }

  void _open(Note? note) {
    selectedId = note?.id;
    title = note?.title ?? '';
    content = note?.content ?? '';
    _revision = _savedRevision = 0;
    isComposing = false;
    error = null;
    editorVersion++;
  }

  Future<bool> deleteSelected() async {
    if (selectedId == null || isSwitching) return false;
    isSwitching = true;
    _emit();
    try {
      // Wait for outstanding writes before deleting so they cannot recreate data.
      if (!await flush() || _disposed) return false;
      final id = selectedId!;
      await service.deleteNote(id);
      if (_disposed) return false;
      _notes.removeWhere((note) => note.id == id);
      _open(_notes.isEmpty ? null : _notes.first);
      return true;
    } catch (e) {
      error = _message(e);
      return false;
    } finally {
      isSwitching = false;
      _emit();
    }
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
