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
  return map;
}
