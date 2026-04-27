import 'dart:convert';

import '../models/auth_response.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  AuthService({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.postJson(
      '/auth/register',
      {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response.body, 'サインアップに失敗しました'));
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.postForm(
      '/auth/login',
      {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body, 'ログインに失敗しました'));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthResponse.fromJson(data);
  }

  Future<User> getMe() async {
    final response = await apiClient.get('/users/me');

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body, 'ユーザー情報の取得に失敗しました'));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data);
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