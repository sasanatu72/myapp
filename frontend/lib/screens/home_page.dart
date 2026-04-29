import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/preference_controller.dart';
import '../models/user_preference.dart';
import 'calendar_page.dart';
import 'note_page.dart';
import 'settings_page.dart';
import 'todo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<String> _defaultTabs = [
    'calendar',
    'todo',
    'note',
    'settings',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final controller = context.read<PreferenceController>();
      await controller.loadPreferences();

      final pref = controller.preference;
      if (pref == null) return;

      final mergedEnabledTabs = <String>[
        ...pref.enabledTabs.where((e) => e != 'settings'),
        'settings',
      ];

      final mergedTabOrder = <String>[
        ...pref.tabOrder.where((e) => e != 'settings'),
        'settings',
      ];

      final currentTabs =
          mergedTabOrder.where(mergedEnabledTabs.contains).toList();
      final initialIndex = currentTabs.indexOf(pref.initialTab);

      if (mounted) {
        setState(() {
          _selectedIndex = initialIndex >= 0 ? initialIndex : 0;
        });
      }
    });
  }

  List<String> _resolvedTabs(UserPreference? pref) {
    if (pref == null) return _defaultTabs;

    final enabledTabs = <String>[
      ...pref.enabledTabs.where((e) => e != 'settings'),
      'settings',
    ];

    final tabOrder = <String>[
      ...pref.tabOrder.where((e) => e != 'settings'),
      'settings',
    ];

    return tabOrder.where(enabledTabs.contains).toList();
  }

  Widget _buildPage(String tabKey) {
    switch (tabKey) {
      case 'calendar':
        return const CalendarPage();
      case 'todo':
        return const TodoPage();
      case 'note':
        return const NotePage();
      case 'settings':
        return const SettingsPage();
      default:
        return const Center(child: Text('未対応のタブです'));
    }
  }

  BottomNavigationBarItem _buildNavItem(String tabKey) {
    switch (tabKey) {
      case 'calendar':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'カレンダー',
        );
      case 'todo':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.check_box),
          label: 'タスク',
        );
      case 'note':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.note),
          label: 'ノート',
        );
      case 'settings':
        return const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: '設定',
        );
      default:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.help),
          label: '不明',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferenceController = context.watch<PreferenceController>();

    if (preferenceController.isLoading &&
        preferenceController.preference == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tabs = _resolvedTabs(preferenceController.preference);
    final currentIndex = _selectedIndex >= tabs.length ? 0 : _selectedIndex;

    return Scaffold(
      body: _buildPage(tabs[currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: tabs.map((tab) {
          final item = _buildNavItem(tab);
          return NavigationDestination(
            icon: item.icon,
            label: item.label ?? '',
          );
        }).toList(),
      ),
    );
  }
}