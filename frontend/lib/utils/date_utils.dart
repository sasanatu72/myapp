import '../models/event.dart';

DateTime dateOnly(DateTime d) {
  return DateTime(d.year, d.month, d.day);
}

Map<DateTime, List<Event>> groupEventsByDate(List<Event> events) {
  final Map<DateTime, List<Event>> map = {};

  for (final event in events) {
    final day = dateOnly(event.startTime);
    map.putIfAbsent(day, () => []);
    map[day]!.add(event);
  }

  for (final list in map.values) {
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  return map;
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}

String formatDate(DateTime date) {
  final d = date.toLocal();
  return '${d.year}/${_twoDigits(d.month)}/${_twoDigits(d.day)}';
}

String formatMonthDay(DateTime date) {
  final d = date.toLocal();
  return '${d.month}月${d.day}日';
}

String formatTime(DateTime date) {
  final d = date.toLocal();
  return '${_twoDigits(d.hour)}:${_twoDigits(d.minute)}';
}

String formatDateTime(DateTime date) {
  final d = date.toLocal();
  return '${formatDate(d)} ${formatTime(d)}';
}