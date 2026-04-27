import 'dart:convert';

import '../models/event.dart';
import 'api_client.dart';

class EventService {
  EventService({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<List<Event>> getEvents() async {
    final response = await apiClient.get('/events');

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body, 'イベント取得に失敗しました'));
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Event.fromJson(e)).toList();
  }

  Future<void> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await apiClient.postJson(
      '/events',
      {
        'title': title,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response.body, 'イベント作成に失敗しました'));
    }
  }

  Future<void> updateEvent({
    required int id,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await apiClient.putJson(
      '/events/$id',
      {
        'title': title,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body, 'イベント更新に失敗しました'));
    }
  }


  Future<void> deleteEvent(int id) async {
    final response = await apiClient.delete('/events/$id');

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body, 'イベント削除に失敗しました'));
    }
  }

  String _extractErrorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {}
    return fallback;
  }
}