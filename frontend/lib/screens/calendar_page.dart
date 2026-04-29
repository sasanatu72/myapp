import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../utils/date_utils.dart';
import '../widgets/app_page_container.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import 'event_create_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<DateTime, List<Event>> _eventsByDay = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadEvents);
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eventService = context.read<EventService>();
      final events = await eventService.getEvents();

      if (!mounted) return;

      setState(() {
        _eventsByDay = groupEventsByDate(events);
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

  List<Event> _getEventsForDay(DateTime day) {
    return _eventsByDay[dateOnly(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: AppPageContainer(
        maxWidth: 760,
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildBody(events),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const EventCreatePage(),
            ),
          );

          if (result == true) {
            await _loadEvents();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(List<Event> events) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadEvents,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SelectedDayHeader(
          selectedDay: _selectedDay,
          eventCount: events.length,
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Expanded(
            child: EmptyState(
              icon: Icons.event_busy,
              title: 'この日の予定はありません',
              message: '右下の＋ボタンから予定を追加できます。',
              actionLabel: 'イベントを追加',
              onAction: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EventCreatePage(),
                  ),
                );

                if (result == true) {
                  await _loadEvents();
                }
              },
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = events[index];
                return _EventCard(
                  event: event,
                  onTap: () => _openEventEditor(event),
                  onEdit: () => _openEventEditor(event),
                  onDelete: () => _deleteEvent(event),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _openEventEditor(Event event) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EventCreatePage(event: event),
      ),
    );

    if (result == true) {
      await _loadEvents();
    }
  }


  Future<void> _deleteEvent(Event event) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('イベントを削除しますか？'),
          content: Text('「${event.title}」を削除します。'),
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
      await context.read<EventService>().deleteEvent(event.id);
      await _loadEvents();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }
}

class _SelectedDayHeader extends StatelessWidget {
  const _SelectedDayHeader({
    required this.selectedDay,
    required this.eventCount,
  });

  final DateTime selectedDay;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${formatMonthDay(selectedDay)}の予定',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Chip(
          label: Text('$eventCount件'),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(formatTime(event.startTime).substring(0, 2)),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${formatTime(event.startTime)} - ${formatTime(event.endTime)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '編集',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: '削除',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}