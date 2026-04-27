import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/preference_controller.dart';
import 'screens/auth_gate.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'services/note_service.dart';
import 'services/preference_service.dart';
import 'services/todo_service.dart';
import 'services/token_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://127.0.0.1:8000",
  );

  final apiClient = ApiClient(
    baseUrl: baseUrl,
  );

  final tokenStorageService = TokenStorageService();
  final authService = AuthService(apiClient: apiClient);
  final eventService = EventService(apiClient: apiClient);
  final preferenceService = PreferenceService(apiClient: apiClient);
  final todoService = TodoService(apiClient: apiClient);
  final noteService = NoteService(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<EventService>.value(value: eventService),
        Provider<PreferenceService>.value(value: preferenceService),
        Provider<TodoService>.value(value: todoService),
        Provider<NoteService>.value(value: noteService),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            authService: authService,
            tokenStorageService: tokenStorageService,
            apiClient: apiClient,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => PreferenceController(
            preferenceService: preferenceService,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final preferenceController = context.watch<PreferenceController>();

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Custom Life App',
      debugShowCheckedModeBanner: false,
      themeMode: preferenceController.themeMode,
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: lightColorScheme.surface,
          selectedItemColor: lightColorScheme.onSurface,
          unselectedItemColor: lightColorScheme.onSurfaceVariant,
          selectedIconTheme: IconThemeData(
            color: lightColorScheme.onSurface,
          ),
          unselectedIconTheme: IconThemeData(
            color: lightColorScheme.onSurfaceVariant,
          ),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkColorScheme.surface,
          selectedItemColor: darkColorScheme.onSurface,
          unselectedItemColor: darkColorScheme.onSurfaceVariant,
          selectedIconTheme: IconThemeData(
            color: darkColorScheme.onSurface,
          ),
          unselectedIconTheme: IconThemeData(
            color: darkColorScheme.onSurfaceVariant,
          ),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const AuthGate(),
    );
  }
}