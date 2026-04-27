import 'dart:convert';

import '../models/user_preference.dart';
import 'api_client.dart';

class PreferenceService {
  PreferenceService({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<UserPreference> getMyPreferences() async {
    final response = await apiClient.get('/preferences/me');

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body, '設定の取得に失敗しました'));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return UserPreference.fromJson(data);
  }

  Future<UserPreference> updateMyPreferences(UserPreference preference) async {
    final response = await apiClient.putJson(
      '/preferences/me',
      preference.toJson(),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body, '設定の保存に失敗しました'));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return UserPreference.fromJson(data);
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