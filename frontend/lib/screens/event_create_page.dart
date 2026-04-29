import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../utils/date_utils.dart';
import '../widgets/app_page_container.dart';

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
  late DateTime _startTime;
  late DateTime _endTime;

  bool _isSaving = false;

  static const double _datePickerHeight = 118;
  static const double _timePickerHeight = 108;
  static const double _pickerItemExtent = 28;

  @override
  void initState() {
    super.initState();

    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');

    if (event != null) {
      _date = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      _startTime = event.startTime;
      _endTime = event.endTime;
    } else {
      final now = DateTime.now();
      _date = DateTime(now.year, now.month, now.day);

      _startTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
      );

      _endTime = _startTime.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  DateTime _mergeDateAndTime(DateTime date, DateTime time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  bool get _isInvalidTimeRange => !_endTime.isAfter(_startTime);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'イベント編集' : 'イベント作成'),
      ),
      body: AppPageContainer(
        maxWidth: 640,
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                prefixIcon: Icon(Icons.event_note),
              ),
            ),
            const SizedBox(height: 16),

            _PickerSection(
              title: '日付',
              value: formatDate(_date),
              icon: Icons.calendar_today,
              child: SizedBox(
                height: _datePickerHeight,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _date,
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime(2100),
                  itemExtent: _pickerItemExtent,
                  changeReportingBehavior: ChangeReportingBehavior.onScrollEnd,
                  onDateTimeChanged: (value) {
                    setState(() {
                      _date = DateTime(value.year, value.month, value.day);
                      _startTime = _mergeDateAndTime(_date, _startTime);
                      _endTime = _mergeDateAndTime(_date, _endTime);
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            _PickerSection(
              title: '開始時間',
              value: formatTime(_startTime),
              icon: Icons.schedule,
              child: SizedBox(
                height: _timePickerHeight,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: _startTime,
                  use24hFormat: true,
                  minuteInterval: 5,
                  itemExtent: _pickerItemExtent,
                  changeReportingBehavior: ChangeReportingBehavior.onScrollEnd,
                  onDateTimeChanged: (value) {
                    setState(() {
                      final newStartTime = _mergeDateAndTime(_date, value);
                      _startTime = newStartTime;

                      if (!_endTime.isAfter(_startTime)) {
                        _endTime = _startTime.add(const Duration(hours: 1));
                      }
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            _PickerSection(
              title: '終了時間',
              value: formatTime(_endTime),
              icon: Icons.schedule_outlined,
              child: SizedBox(
                height: _timePickerHeight,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: _endTime,
                  use24hFormat: true,
                  minuteInterval: 5,
                  itemExtent: _pickerItemExtent,
                  changeReportingBehavior: ChangeReportingBehavior.onScrollEnd,
                  onDateTimeChanged: (value) {
                    setState(() {
                      _endTime = _mergeDateAndTime(_date, value);
                    });
                  },
                ),
              ),
            ),

            if (_isInvalidTimeRange) ...[
              const SizedBox(height: 12),
              Text(
                '終了時間は開始時間より後にしてください。',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

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
    );
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _showMessage('タイトルを入力してください');
      return;
    }

    if (_isInvalidTimeRange) {
      _showMessage('終了時間は開始時間より後にしてください');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final eventService = context.read<EventService>();

      if (widget.isEdit) {
        await eventService.updateEvent(
          id: widget.event!.id,
          title: _titleController.text.trim(),
          startTime: _startTime,
          endTime: _endTime,
        );
      } else {
        await eventService.createEvent(
          title: _titleController.text.trim(),
          startTime: _startTime,
          endTime: _endTime,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
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

class _PickerSection extends StatelessWidget {
  const _PickerSection({
    required this.title,
    required this.value,
    required this.icon,
    required this.child,
  });

  final String title;
  final String value;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}