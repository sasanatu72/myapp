import 'package:flutter/material.dart';

import '../models/note_content.dart';

/// Native builds retain the original plain text editor. Rich documents are
/// read-only here so opening one never discards its formatting.
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
  late final title = TextEditingController(text: widget.title);
  late final body = TextEditingController(
    text: NoteContent.decode(widget.content).text,
  );
  late final richText = NoteContent.decode(widget.content).isRichText;

  @override
  void initState() {
    super.initState();
    title.addListener(_changed);
    body.addListener(_changed);
  }

  void _changed() => widget.onChanged(
    title.text,
    richText ? widget.content : body.text,
    title.value.composing.isValid || body.value.composing.isValid,
  );

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        TextField(
          controller: title,
          enabled: widget.enabled,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(hintText: '無題のノート'),
        ),
        if (richText)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('書式付きノートの本文編集はWeb版で利用できます。'),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: TextField(
            controller: body,
            enabled: widget.enabled,
            readOnly: richText,
            expands: true,
            minLines: null,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 14, height: 1.3),
            scrollPadding: const EdgeInsets.all(20),
            decoration: const InputDecoration(hintText: '本文を入力'),
          ),
        ),
      ],
    ),
  );
}
