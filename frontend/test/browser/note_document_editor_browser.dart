// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp_frontend/models/note_content.dart';
import 'package:myapp_frontend/widgets/note_document_editor.dart';

void main() {
  testWidgets('native editing does not invoke Flutter keyboard shortcuts', (
    tester,
  ) async {
    var intercepted = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Focus(
            autofocus: true,
            onKeyEvent: (_, event) {
              intercepted++;
              return KeyEventResult.handled;
            },
            child: NoteDocumentEditor(
              title: '',
              content: '本文',
              hasUnsavedChanges: false,
              onChanged: (_, _, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    (html.document.querySelector('.note-body') as html.DivElement).focus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(intercepted, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'browser editor preserves literal text and emits formatted lists',
    (tester) async {
      var saved = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteDocumentEditor(
              title: '日本語',
              content: '<b>これは既存の文字列</b>',
              hasUnsavedChanges: false,
              onChanged: (_, content, _) => saved = content,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final body = html.document.querySelector('.note-body') as html.DivElement;
      expect(body.text, '<b>これは既存の文字列</b>');
      expect(body.querySelector('b'), isNull);
      body.focus();
      final range = html.document.createRange()..selectNodeContents(body);
      html.window.getSelection()!
        ..removeAllRanges()
        ..addRange(range);
      html.document.querySelector('button[aria-label="箇条書き"]')!.click();
      await tester.pump();
      expect(body.querySelector('ul li'), isNotNull);
      expect(NoteContent.decode(saved).html, contains('<ul>'));
      final persisted = saved;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteDocumentEditor(
              title: '日本語',
              content: persisted,
              hasUnsavedChanges: false,
              onChanged: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(html.document.querySelector('.note-body ul li'), isNotNull);
    },
  );

  testWidgets('composition and save rebuilds keep DOM and caret intact', (
    tester,
  ) async {
    final calls = <bool>[];
    final dirty = ValueNotifier(false);
    addTearDown(dirty.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: dirty,
            builder: (_, value, _) => NoteDocumentEditor(
              title: '',
              content: '',
              hasUnsavedChanges: value,
              onChanged: (_, _, composing) => calls.add(composing),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final body = html.document.querySelector('.note-body') as html.DivElement;
    body.focus();
    body.dispatchEvent(html.CompositionEvent('compositionstart', data: 'に'));
    body.text = 'にほんご';
    body.dispatchEvent(html.Event('input'));
    await tester.pump();
    expect(calls.last, true);
    expect(
      (html.document.querySelector('button[aria-label="箇条書き"]')
              as html.ButtonElement)
          .disabled,
      true,
    );
    body.text = '日本語';
    body.dispatchEvent(html.CompositionEvent('compositionend', data: '日本語'));
    final range = html.document.createRange()
      ..selectNodeContents(body)
      ..collapse(false);
    html.window.getSelection()!
      ..removeAllRanges()
      ..addRange(range);
    final anchor = html.window.getSelection()!.anchorNode;
    dirty.value = true;
    await tester.pump();
    expect(identical(html.document.querySelector('.note-body'), body), true);
    expect(html.window.getSelection()!.anchorNode, anchor);
    expect(body.text, '日本語');
    expect(calls.last, false);
  });

  testWidgets(
    'stored markup cannot restore executable elements or attributes',
    (tester) async {
      const content = NoteContent(
        text: '安全な本文',
        html:
            '<p onclick="alert(1)"><b>安全な本文</b></p>'
            '<img src="invalid" onerror="alert(1)"><script>alert(1)</script>'
            '<iframe src="https://example.com"></iframe>',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteDocumentEditor(
              title: '復元',
              content: content.encode(),
              hasUnsavedChanges: false,
              onChanged: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final body = html.document.querySelector('.note-body')!;
      expect(body.querySelector('b')!.text, '安全な本文');
      expect(body.querySelector('img,script,iframe,[onclick]'), isNull);
    },
  );
}
