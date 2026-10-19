// Browser-owned editable DOM keeps the native IME caret and candidate window
// in the same coordinate space. Do not mirror each keystroke back into the DOM.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../models/note_content.dart';

class NoteDocumentEditor extends StatefulWidget {
  const NoteDocumentEditor({
    super.key,
    required this.title,
    required this.content,
    required this.onChanged,
    required this.hasUnsavedChanges,
    this.enabled = true,
  });
  final String title;
  final String content;
  final bool hasUnsavedChanges;
  final bool enabled;
  final void Function(String title, String content, bool composing) onChanged;

  @override
  State<NoteDocumentEditor> createState() => _NoteDocumentEditorState();
}

class _NoteDocumentEditorState extends State<NoteDocumentEditor> {
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _buttons = <html.ButtonElement>[];
  final _toggleButtons = <String, html.ButtonElement>{};
  final _nativeFocus = FocusNode(
    debugLabel: 'Native note editor',
    skipTraversal: true,
  );
  html.DivElement? _root;
  late html.InputElement _title;
  late html.DivElement _body;
  late html.DivElement _scroll;
  late html.SelectElement _blockStyle;
  html.Range? _selection;
  bool _composing = false;
  late String _content = widget.content;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(_routeNativeEditingKeys);
  }

  // The web engine listens on window in the capture phase. Stopping a DOM
  // event at the editor would be too late: Flutter's focused button/TextField
  // may already have prevented Enter, arrows or Tab. Let the browser process
  // keys while a control inside this platform view owns the DOM focus.
  KeyEventResult _routeNativeEditingKeys(KeyEvent event) {
    if (_hasNativeFocus) _claimNativeFocus();
    return KeyEventResult.ignored;
  }

  bool get _hasNativeFocus =>
      widget.enabled && (_root?.contains(html.document.activeElement) ?? false);

  void _claimNativeFocus() {
    if (_hasNativeFocus && !_nativeFocus.hasPrimaryFocus) {
      _nativeFocus.requestFocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
  }

  String _color(Color value) =>
      '#${value.toARGB32().toRadixString(16).substring(2)}';

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _nativeFocus,
    onKeyEvent: (_, event) => _hasNativeFocus
        ? KeyEventResult.skipRemainingHandlers
        : KeyEventResult.ignored,
    child: HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: (element) => _create(element as html.DivElement),
    ),
  );

  void _create(html.DivElement root) {
    _root = root;
    _subscriptions.add(
      const html.EventStreamProvider<html.Event>(
        'focusin',
      ).forElement(root).listen((_) => _claimNativeFocus()),
    );
    root.classes.add('life-note-editor');
    root.style.cssText =
        'width:100%;height:100%;display:flex;flex-direction:column;'
        'overflow:hidden;box-sizing:border-box;font-family:"Noto Sans JP",'
        '"Hiragino Sans","Yu Gothic",Meiryo,sans-serif;';
    final style = html.StyleElement()
      ..text = '''
      .life-note-editor * { box-sizing: border-box; }
      .life-note-editor .note-toolbar { display:flex;align-items:center;gap:4px;
        padding:8px 12px;flex-wrap:wrap;flex-shrink:0;border-bottom:1px solid var(--line); }
      .life-note-editor button,.life-note-editor select { color:var(--ink);
        background:transparent;border:1px solid var(--line);border-radius:6px;
        min-width:34px;height:34px;font:inherit;font-size:14px;cursor:pointer; }
      .life-note-editor select { background:var(--paper);border-color:var(--line); }
      .life-note-editor button:hover,.life-note-editor button[aria-pressed="true"]
        { background:var(--active);color:var(--accent); }
      .life-note-editor button:focus-visible,.life-note-editor select:focus-visible
        { outline:2px solid var(--accent);outline-offset:2px; }
      .life-note-editor button:disabled { opacity:.4;cursor:default; }
      .life-note-editor .note-scroll { flex:1;min-height:0;overflow:auto;
        padding:24px;overscroll-behavior:contain;scroll-padding:24px;container-type:inline-size; }
      .life-note-editor .note-paper { width:100%;max-width:800px;
        min-height:1131.43px;min-height:min(1131.43px, calc(100cqw * 1.414285714));
        display:flex;flex-direction:column;margin:0 auto;
        padding:36px 48px 64px;background:var(--paper);border:1px solid var(--line);
        border-radius:8px;color:var(--ink); }
      .life-note-editor .note-title { display:block;width:100%;padding:0 0 20px;
        margin:0 0 24px;border:0;border-bottom:1px solid var(--line);outline:0;
        border-radius:0;background:transparent;color:var(--ink);font:inherit;
        font-size:22px;font-weight:700;line-height:1.5; }
      .life-note-editor .note-body { flex:1 0 auto;min-height:320px;outline:none;font-size:14px;
        line-height:1.75;overflow-wrap:anywhere;white-space:pre-wrap;caret-color:var(--ink); }
      .life-note-editor .note-body:empty:before { content:attr(data-placeholder);
        color:var(--muted);pointer-events:none; }
      .life-note-editor .note-body p,.life-note-editor .note-body div { margin:0 0 6px; }
      .life-note-editor .note-body h1 { font-size:24px;line-height:1.5;margin:24px 0 12px; }
      .life-note-editor .note-body h2 { font-size:20px;line-height:1.6;margin:20px 0 10px; }
      .life-note-editor .note-body h3 { font-size:17px;margin:16px 0 8px; }
      .life-note-editor .note-body ul,.life-note-editor .note-body ol { padding-left:28px; }
      .life-note-editor .note-body li { padding-left:4px; }
      .life-note-editor .note-body blockquote { margin:16px 0;padding:4px 16px;
        border-left:3px solid var(--accent);color:var(--muted); }
      .life-note-editor .note-body pre { padding:12px;border-radius:6px;
        background:var(--active);white-space:pre-wrap; }
      @media(max-width:700px) {
        .life-note-editor .note-scroll { padding:8px; }
        .life-note-editor .note-paper { padding:24px 20px 48px;border:0; }
        .life-note-editor .note-title { font-size:20px; }
      }
    ''';
    root.append(style);
    final toolbar = html.DivElement()
      ..classes.add('note-toolbar')
      ..setAttribute('role', 'toolbar')
      ..setAttribute('aria-label', '文字の書式');
    _blockStyle = html.SelectElement()..setAttribute('aria-label', '段落のスタイル');
    for (final item in {
      'p': '標準テキスト',
      'h1': '見出し 1',
      'h2': '見出し 2',
      'h3': '見出し 3',
      'blockquote': '引用',
      'pre': 'コード',
    }.entries) {
      _blockStyle.append(html.OptionElement(data: item.value, value: item.key));
    }
    toolbar.append(_blockStyle);
    _subscriptions.add(
      _blockStyle.onChange.listen((_) {
        _run('formatBlock', _blockStyle.value ?? 'p');
      }),
    );
    _addButton(toolbar, '↶', '元に戻す (Ctrl+Z)', 'undo');
    _addButton(toolbar, '↷', 'やり直す (Ctrl+Shift+Z)', 'redo');
    _addButton(toolbar, 'B', '太字 (Ctrl+B)', 'bold', css: 'font-weight:700');
    _addButton(toolbar, 'I', '斜体 (Ctrl+I)', 'italic', css: 'font-style:italic');
    _addButton(
      toolbar,
      'U',
      '下線 (Ctrl+U)',
      'underline',
      css: 'text-decoration:underline',
    );
    _addButton(
      toolbar,
      'S',
      '取り消し線',
      'strikeThrough',
      css: 'text-decoration:line-through',
    );
    _addButton(toolbar, '• ≡', '箇条書き', 'insertUnorderedList');
    _addButton(toolbar, '1. ≡', '番号付きリスト', 'insertOrderedList');
    _addButton(toolbar, '⇤', 'インデントを減らす', 'outdent');
    _addButton(toolbar, '⇥', 'インデントを増やす', 'indent');
    _addButton(toolbar, 'Tx', '文字の書式をクリア', 'removeFormat');
    root.append(toolbar);

    _scroll = html.DivElement()..classes.add('note-scroll');
    final paper = html.DivElement()..classes.add('note-paper');
    _title = html.InputElement(type: 'text')
      ..classes.add('note-title')
      ..value = widget.title
      ..placeholder = '無題のノート'
      ..setAttribute('aria-label', 'ノートのタイトル');
    _body = html.DivElement()
      ..classes.add('note-body')
      ..contentEditable = 'true'
      ..spellcheck = false
      ..setAttribute('role', 'textbox')
      ..setAttribute('aria-label', 'ノートの本文')
      ..setAttribute('aria-multiline', 'true')
      ..setAttribute('data-placeholder', 'ここから書き始めましょう…');
    final document = NoteContent.decode(widget.content);
    if (document.html != null) {
      _body.setInnerHtml(document.html!, validator: _DocumentValidator());
    } else {
      // textContent, never innerHTML: old notes may contain literal HTML/code.
      _body.text = document.text;
    }
    paper
      ..append(_title)
      ..append(_body);
    _scroll.append(paper);
    root.append(_scroll);
    _subscriptions.add(
      _title.onInput.listen((_) => _changed(bodyChanged: false)),
    );
    _subscriptions.add(
      _body.onInput.listen((_) => _changed(bodyChanged: true)),
    );
    _subscriptions.add(_body.onKeyDown.listen(_handleBodyKey));
    for (final element in [_title, _body]) {
      _subscriptions.add(
        const html.EventStreamProvider<html.Event>(
          'compositionstart',
        ).forElement(element).listen((_) {
          _composing = true;
          _changed(bodyChanged: element == _body);
          _updateEnabled();
        }),
      );
      _subscriptions.add(
        const html.EventStreamProvider<html.Event>(
          'compositionend',
        ).forElement(element).listen((_) {
          _composing = false;
          _changed(bodyChanged: element == _body);
          _updateEnabled();
        }),
      );
    }
    _subscriptions.add(
      html.document.onSelectionChange.listen((_) => _rememberSelection()),
    );
    _subscriptions.add(
      _body.onPaste.listen((event) {
        event.preventDefault();
        final clipboard = event.clipboardData;
        if (clipboard != null) {
          html.document.execCommand(
            'insertText',
            false,
            clipboard.getData('text/plain'),
          );
          _changed(bodyChanged: true);
        }
      }),
    );
    // Prevent dropped images/HTML or browser navigation from entering a document.
    _subscriptions.add(_body.onDrop.listen((event) => event.preventDefault()));
    _subscriptions.add(
      html.window.onBeforeUnload.listen((event) {
        if (widget.hasUnsavedChanges || _composing) {
          event.preventDefault();
          (event as html.BeforeUnloadEvent).returnValue = '';
        }
      }),
    );
    _applyTheme();
    _updateEnabled();
  }

  html.Element? _listItemAtCaret() {
    final selection = html.window.getSelection();
    if (selection == null || !_body.contains(selection.anchorNode)) return null;
    var node = selection.anchorNode;
    while (node != null && node != _body) {
      if (node is html.Element && node.localName == 'li') return node;
      node = node.parentNode;
    }
    return null;
  }

  void _handleBodyKey(html.KeyboardEvent event) {
    // Enter confirms an IME candidate while composing; never turn that into
    // a paragraph/list command. 229 also covers browser/IME event ordering.
    if (_composing ||
        event.keyCode == 229 ||
        !widget.enabled ||
        event.ctrlKey ||
        event.metaKey ||
        event.altKey) {
      return;
    }
    final item = _listItemAtCaret();
    if (item == null) return;
    if (event.key == 'Tab') {
      event.preventDefault();
      _rememberSelection();
      _run(event.shiftKey ? 'outdent' : 'indent');
    } else if (event.key == 'Enter' &&
        !event.shiftKey &&
        (html.window.getSelection()?.isCollapsed ?? false) &&
        (item.text ?? '')
            .replaceAll(RegExp('[\u200B\uFEFF]'), '')
            .trim()
            .isEmpty) {
      // A blank nested item moves up one level. At the top level this exits
      // the list; Enter on a populated item keeps the normal sibling behavior.
      event.preventDefault();
      _rememberSelection();
      _run('outdent');
    }
  }

  void _addButton(
    html.DivElement toolbar,
    String label,
    String title,
    String command, {
    String? css,
  }) {
    final button = html.ButtonElement()
      ..type = 'button'
      ..text = label
      ..title = title
      ..setAttribute('aria-label', title);
    if (css != null) button.style.cssText = css;
    if ([
      'bold',
      'italic',
      'underline',
      'strikeThrough',
      'insertUnorderedList',
      'insertOrderedList',
    ].contains(command)) {
      _toggleButtons[command] = button;
      button.setAttribute('aria-pressed', 'false');
    }
    _subscriptions.add(
      button.onMouseDown.listen((event) => event.preventDefault()),
    );
    _subscriptions.add(button.onClick.listen((_) => _run(command)));
    _buttons.add(button);
    toolbar.append(button);
  }

  void _rememberSelection() {
    final selection = html.window.getSelection();
    if (selection == null ||
        selection.rangeCount == 0 ||
        !_body.contains(selection.anchorNode)) {
      return;
    }
    _selection = selection.getRangeAt(0).cloneRange();
    for (final item in _toggleButtons.entries) {
      item.value.setAttribute(
        'aria-pressed',
        '${html.document.queryCommandState(item.key)}',
      );
    }
    var node = selection.anchorNode;
    while (node != null && node != _body) {
      if (node is html.Element &&
          [
            'p',
            'h1',
            'h2',
            'h3',
            'blockquote',
            'pre',
          ].contains(node.localName)) {
        _blockStyle.value = node.localName;
        return;
      }
      node = node.parentNode;
    }
    _blockStyle.value = 'p';
  }

  void _run(String command, [String? value]) {
    if (!widget.enabled || _composing) return;
    _body.focus();
    if (_selection != null) {
      html.window.getSelection()
        ?..removeAllRanges()
        ..addRange(_selection!);
    }
    // Editing commands preserve the browser's undo history and IME behavior.
    html.document.execCommand('styleWithCSS', false, 'false');
    html.document.execCommand(command, false, value);
    _changed(bodyChanged: true);
    _rememberSelection();
    _ensureCaretVisible();
  }

  void _ensureCaretVisible() {
    final selection = html.window.getSelection();
    if (selection == null ||
        selection.rangeCount == 0 ||
        !_body.contains(selection.anchorNode)) {
      return;
    }
    final caret = selection.getRangeAt(0).getBoundingClientRect();
    final viewport = _scroll.getBoundingClientRect();
    if (caret.height == 0) return;
    if (caret.top < viewport.top + 20) {
      _scroll.scrollTop += (caret.top - viewport.top - 20).round();
    } else if (caret.bottom > viewport.bottom - 20) {
      _scroll.scrollTop += (caret.bottom - viewport.bottom + 20).round();
    }
  }

  void _changed({required bool bodyChanged}) {
    if (bodyChanged) {
      final safe = html.DivElement()
        ..setInnerHtml(_body.innerHtml, validator: _DocumentValidator());
      _content = NoteContent(
        text: _body.innerText,
        html: safe.innerHtml,
      ).encode();
    }
    widget.onChanged(_title.value ?? '', _content, _composing);
  }

  void _updateEnabled() {
    if (_title.disabled != !widget.enabled) _title.disabled = !widget.enabled;
    final editable = widget.enabled ? 'true' : 'false';
    if (_body.contentEditable != editable) _body.contentEditable = editable;
    _blockStyle.disabled = !widget.enabled || _composing;
    for (final button in _buttons) {
      button.disabled = !widget.enabled || _composing;
    }
    _root?.style.visibility = widget.enabled ? 'visible' : 'hidden';
  }

  void _applyTheme() {
    final colors = Theme.of(context).colorScheme;
    final root = _root;
    if (root == null) return;
    for (final color in {
      '--ink': colors.onSurface,
      '--muted': colors.onSurfaceVariant,
      '--paper': colors.surface,
      '--line': colors.outlineVariant,
      '--active': colors.primaryContainer,
      '--accent': colors.primary,
    }.entries) {
      root.style.setProperty(color.key, _color(color.value));
    }
    root.style.backgroundColor = _color(colors.surfaceContainerLow);
    root.style.setProperty(
      'color-scheme',
      colors.brightness == Brightness.dark ? 'dark' : 'light',
    );
  }

  @override
  void didUpdateWidget(NoteDocumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_root == null) return;
    _updateEnabled();
    _applyTheme();
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_routeNativeEditingKeys);
    _nativeFocus.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _root?.children.clear();
    super.dispose();
  }
}

/// Only document structure and inline emphasis. No URLs, scripts, styles, IDs,
/// event handlers, images, or embedded content may be restored from the DB.
class _DocumentValidator implements html.NodeValidator {
  static const tags = {
    'p',
    'div',
    'br',
    'strong',
    'b',
    'em',
    'i',
    'u',
    's',
    'strike',
    'span',
    'h1',
    'h2',
    'h3',
    'ul',
    'ol',
    'li',
    'blockquote',
    'pre',
    'code',
  };
  @override
  bool allowsElement(html.Element element) => tags.contains(element.localName);
  @override
  bool allowsAttribute(html.Element element, String name, String value) =>
      false;
}
