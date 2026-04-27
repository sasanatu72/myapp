import 'package:flutter/material.dart';

import '../models/user_preference.dart';
import '../services/preference_service.dart';

class PreferenceController extends ChangeNotifier {
  PreferenceController({
    required this.preferenceService,
  });

  final PreferenceService preferenceService;

  UserPreference? _preference;
  bool _isLoading = false;
  String? _errorMessage;

  UserPreference? get preference => _preference;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ThemeMode get themeMode {
    final mode = _preference?.themeMode ?? 'system';
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> loadPreferences() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _preference = await preferenceService.getMyPreferences();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePreferences(UserPreference updated) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _preference = await preferenceService.updateMyPreferences(updated);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _preference = null;
    _errorMessage = null;
    notifyListeners();
  }
}