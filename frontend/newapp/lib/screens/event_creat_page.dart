import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../services/event_service.dart';

class EventCreatePage extends StatefulWidget {
  const EventCreatePage({
    super.key,
    this.event,
  });

  final Event? event;

  bool get isEdit => event != null;

  @override
  State<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends State<EventCreatePage> {
  late final TextEditingController _titleController;
  late DateTime _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');

    if (event != null) {
      _date = event.startTime;
      _start = TimeOfDay.fromDateTime(event.startTime);
      _end = TimeOfDay.fromDateTime(event.endTime);
    } else {
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'イベント編集' : 'イベント作成'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickDate,
              child: Text("日付: ${_date.toLocal()}".split(' ')[0]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickStart,
              child: Text(
                _start == null ? "開始時間" : "開始: ${_start!.format(context)}",
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickEnd,
              child: Text(
                _end == null ? "終了時間" : "終了: ${_end!.format(context)}",
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEdit ? "更新" : "保存"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _date = d);
    }
  }

  Future<void> _pickStart() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _start ?? TimeOfDay.now(),
    );
    if (t != null) {
      setState(() => _start = t);
    }
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _end ?? TimeOfDay.now(),
    );
    if (t != null) {
      setState(() => _end = t);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _showMessage('タイトルを入力してください');
      return;
    }
    if (_start == null || _end == null) {
      _showMessage('開始時間と終了時間を選択してください');
      return;
    }

    final startTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _start!.hour,
      _start!.minute,
    );

    final endTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _end!.hour,
      _end!.minute,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      final eventService = context.read<EventService>();

      if (widget.isEdit) {
        await eventService.updateEvent(
          id: widget.event!.id,
          title: _titleController.text.trim(),
          startTime: startTime,
          endTime: endTime,
        );
      } else {
        await eventService.createEvent(
          title: _titleController.text.trim(),
          startTime: startTime,
          endTime: endTime,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}