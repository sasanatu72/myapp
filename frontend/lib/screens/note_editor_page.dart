import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/app_page_container.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    super.key,
    this.note,
  });

  final Note? note;

  bool get isEdit => note != null;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final service = context.read<NoteService>();

      if (widget.isEdit) {
        await service.updateNote(
          id: widget.note!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
      } else {
        await service.createNote(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'ノート編集' : 'ノート作成'),
      ),
      body: AppPageContainer(
        maxWidth: 720,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                minLines: 8,
                maxLines: 16,
                decoration: const InputDecoration(
                  labelText: '内容',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(widget.isEdit ? '更新する' : '保存する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}