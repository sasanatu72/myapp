import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../utils/date_utils.dart';
import 'event_creat_page.dart';

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eventService = context.read<EventService>();
      final events = await eventService.getEvents();

      setState(() {
        _eventsByDay = groupEventsByDate(events);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _eventsByDay[dateOnly(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
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
          ),
          const Divider(),
          Expanded(
            child: _buildBody(events),
          ),
        ],
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadEvents,
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      );
    }

    if (events.isEmpty) {
      return const Center(
        child: Text('この日のイベントはありません'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final e = events[index];
        return ListTile(
          title: Text(e.title),
          subtitle: Text('${e.startTime} - ${e.endTime}'),
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => EventCreatePage(event: e),
              ),
            );

            if (result == true) {
              await _loadEvents();
            }
          },
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              try {
                await context.read<EventService>().deleteEvent(e.id);
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
            },
          ),
        );
      },
    );
  }
}