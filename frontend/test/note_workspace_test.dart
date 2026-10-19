import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:myapp_frontend/controllers/note_workspace_controller.dart';
import 'package:myapp_frontend/models/note.dart';
import 'package:myapp_frontend/models/note_content.dart';
import 'package:myapp_frontend/screens/note_page.dart';
import 'package:myapp_frontend/screens/note_editor_page.dart';
import 'package:myapp_frontend/services/api_client.dart';
import 'package:myapp_frontend/services/note_service.dart';

Note makeNote(int id, {String content = '本文'}) => Note(
  id: id,
  title: 'ノート $id',
  content: content,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026, 1, id),
);

class FakeNotes extends NoteService {
  FakeNotes([List<Note>? initial])
    : items = initial ?? [],
      super(apiClient: ApiClient(baseUrl: 'http://unused'));
  final List<Note> items;
  Completer<void>? hold;
  bool fail = false;
  int creates = 0;
  int updates = 0;
  final List<String> writes = [];

  @override
  Future<List<Note>> getNotes() async => List.of(items);

  Future<Note> _write(int id, String title, String content) async {
    writes.add(content);
    if (hold != null) await hold!.future;
    if (fail) throw Exception('保存に失敗しました');
    final note = Note(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime(2026),
      updatedAt: DateTime.now(),
    );
    items.removeWhere((item) => item.id == id);
    items.add(note);
    return note;
  }

  @override
  Future<Note> createNote({required String title, required String content}) {
    creates++;
    return _write(100 + creates, title, content);
  }

  @override
  Future<Note> updateNote({
    required int id,
    required String title,
    required String content,
  }) {
    updates++;
    return _write(id, title, content);
  }

  @override
  Future<void> deleteNote(int id) async =>
      items.removeWhere((note) => note.id == id);
}

void main() {
  test('legacy text, literal HTML and unrelated JSON stay unchanged', () {
    for (final text in ['日本語\n本文', '<b>コード</b>', '{"text":"既存のJSON"}']) {
      final decoded = NoteContent.decode(text);
      expect(decoded.isRichText, false);
      expect(decoded.encode(), text);
    }
    const rich = NoteContent(text: '買い物', html: '<ul><li>買い物</li></ul>');
    expect(NoteContent.decode(rich.encode()).html, rich.html);
    expect(NoteContent.decode(rich.encode()).text, '買い物');
  });

  test(
    'slow initial save drains later edits without duplicate new notes',
    () async {
      final service = FakeNotes()..hold = Completer<void>();
      final workspace = NoteWorkspaceController(service);
      addTearDown(workspace.dispose);
      await workspace.load();
      workspace.change('メモ', '最初', composing: false);
      final save = workspace.flush();
      workspace.change('メモ', '入力を続けた本文', composing: false);
      service.hold!.complete();
      expect(await save, true);
      expect(service.creates, 1);
      expect(service.updates, 1);
      expect(service.items.single.content, '入力を続けた本文');
      expect(workspace.content, '入力を続けた本文');
      expect(workspace.isDirty, false);
    },
  );

  test('failed save blocks navigation and retains retryable draft', () async {
    final service = FakeNotes([makeNote(1), makeNote(2)])..fail = true;
    final workspace = NoteWorkspaceController(service);
    addTearDown(workspace.dispose);
    await workspace.load();
    workspace.change('変更', '消えてはいけない本文', composing: false);
    expect(await workspace.select(makeNote(1)), false);
    expect(workspace.selectedId, 2);
    expect(workspace.content, '消えてはいけない本文');
    expect(workspace.isDirty, true);
    service.fail = false;
    expect(await workspace.select(makeNote(1)), true);
    expect(
      service.items.firstWhere((note) => note.id == 2).content,
      '消えてはいけない本文',
    );
  });

  test('IME composition is not saved or switched until committed', () async {
    final service = FakeNotes([makeNote(1)]);
    final workspace = NoteWorkspaceController(service);
    addTearDown(workspace.dispose);
    await workspace.load();
    workspace.change('日本語', 'にほんご', composing: true);
    expect(await workspace.select(null), false);
    expect(service.writes, isEmpty);
    workspace.change('日本語', '日本語', composing: false);
    expect(await workspace.select(null), true);
    expect(service.items.single.content, '日本語');
  });

  test('blank drafts do not create notes', () async {
    final service = FakeNotes();
    final workspace = NoteWorkspaceController(service);
    addTearDown(workspace.dispose);
    await workspace.load();
    workspace.change('', '  ', composing: false);
    expect(await workspace.flush(), true);
    expect(service.creates, 0);
  });

  test('requested note opens instead of most recently updated note', () async {
    final service = FakeNotes([makeNote(1), makeNote(2)]);
    final workspace = NoteWorkspaceController(service);
    addTearDown(workspace.dispose);
    await workspace.load(initialNote: makeNote(1));
    expect(workspace.selectedId, 1);
    await workspace.load(createNew: true);
    expect(workspace.selectedId, isNull);
    expect(workspace.content, isEmpty);
    expect(service.creates, 0);
  });

  testWidgets('note tab starts at list and returns after saving editor', (
    tester,
  ) async {
    final service = FakeNotes([makeNote(1), makeNote(2)]);
    await tester.pumpWidget(
      Provider<NoteService>.value(
        value: service,
        child: const MaterialApp(home: NotePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorPage), findsNothing);
    expect(find.text('ノート 1'), findsOneWidget);
    await tester.tap(find.text('ノート 1'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorPage), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '一覧からの編集');
    await tester.tap(find.byTooltip('一覧に戻る'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorPage), findsNothing);
    expect(find.text('一覧からの編集'), findsOneWidget);
    expect(service.items.firstWhere((note) => note.id == 1).content, '一覧からの編集');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save keeps the editor open when returning to list', (
    tester,
  ) async {
    final service = FakeNotes([makeNote(1)])..fail = true;
    await tester.pumpWidget(
      Provider<NoteService>.value(
        value: service,
        child: const MaterialApp(home: NotePage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ノート 1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '保存前の本文');
    await tester.tap(find.byTooltip('一覧に戻る'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorPage), findsOneWidget);
    expect(service.items.single.content, '本文');
    service.fail = false;
    await tester.tap(find.byTooltip('一覧に戻る'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorPage), findsNothing);
    expect(service.items.single.content, '保存前の本文');
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop lists notes beside editor and switches with save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FakeNotes([makeNote(1), makeNote(2)]);
    await tester.pumpWidget(
      Provider<NoteService>.value(
        value: service,
        child: MaterialApp(home: NoteEditorPage(note: makeNote(2))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('新しいノート'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '編集した本文');
    await tester.tap(find.text('ノート 1'));
    await tester.pumpAndSettle();
    expect(service.items.firstWhere((item) => item.id == 2).content, '編集した本文');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('phone exposes note list in a drawer without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Provider<NoteService>.value(
        value: FakeNotes([makeNote(1)]),
        child: MaterialApp(home: NoteEditorPage(note: makeNote(1))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('ノート一覧'));
    await tester.pumpAndSettle();
    expect(find.text('新しいノート'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
