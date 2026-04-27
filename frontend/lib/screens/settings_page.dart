import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/preference_controller.dart';
import '../models/user_preference.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const List<String> configurableTabs = ['calendar', 'todo', 'note'];

  late List<String> _enabledTabs;
  late List<String> _tabOrder;
  late String _initialTab;
  late String _themeMode;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final pref = context.read<PreferenceController>().preference;
    final safePref = pref ??
        UserPreference(
          enabledTabs: configurableTabs,
          tabOrder: configurableTabs,
          initialTab: 'calendar',
          themeMode: 'system',
        );

    _enabledTabs = List<String>.from(
      safePref.enabledTabs.where(configurableTabs.contains),
    );

    _tabOrder = List<String>.from(
      safePref.tabOrder.where(configurableTabs.contains),
    );

    if (_tabOrder.isEmpty) {
      _tabOrder = List<String>.from(configurableTabs);
    }

    _initialTab = configurableTabs.contains(safePref.initialTab)
        ? safePref.initialTab
        : _enabledTabs.isNotEmpty
            ? _enabledTabs.first
            : configurableTabs.first;

    _themeMode = safePref.themeMode;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final availableInitialTabs =
        _tabOrder.where((tab) => _enabledTabs.contains(tab)).toList();

    if (availableInitialTabs.isNotEmpty &&
        !availableInitialTabs.contains(_initialTab)) {
      _initialTab = availableInitialTabs.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '表示するタブ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ...configurableTabs.map((tab) {
            final isEnabled = _enabledTabs.contains(tab);
            return SwitchListTile(
              title: Text(_labelForTab(tab)),
              value: isEnabled,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    if (!_enabledTabs.contains(tab)) _enabledTabs.add(tab);
                    if (!_tabOrder.contains(tab)) _tabOrder.add(tab);
                    if (_enabledTabs.length == 1) _initialTab = tab;
                  } else {
                    if (_enabledTabs.length == 1 && _enabledTabs.contains(tab)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('少なくとも1つのタブは表示してください')),
                      );
                      return;
                    }
                    _enabledTabs.remove(tab);
                  }
                });
              },
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'タブ順',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tabOrder.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _tabOrder.removeAt(oldIndex);
                _tabOrder.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final tab = _tabOrder[index];
              return ListTile(
                key: ValueKey(tab),
                title: Text(_labelForTab(tab)),
                leading: const Icon(Icons.drag_handle),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            '初期タブ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          DropdownButtonFormField<String>(
            value: availableInitialTabs.isNotEmpty ? _initialTab : null,
            items: availableInitialTabs
                .map(
                  (tab) => DropdownMenuItem(
                    value: tab,
                    child: Text(_labelForTab(tab)),
                  ),
                )
                .toList(),
            onChanged: availableInitialTabs.isEmpty
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _initialTab = value;
                      });
                    }
                  },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'テーマ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          DropdownButtonFormField<String>(
            value: _themeMode,
            items: const [
              DropdownMenuItem(value: 'system', child: Text('System')),
              DropdownMenuItem(value: 'light', child: Text('Light')),
              DropdownMenuItem(value: 'dark', child: Text('Dark')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _themeMode = value;
                });
              }
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('設定を保存'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              context.read<PreferenceController>().clear();
              await context.read<AuthController>().logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }

  String _labelForTab(String tab) {
    switch (tab) {
      case 'calendar':
        return 'Calendar';
      case 'todo':
        return 'Todo';
      case 'note':
        return 'Note';
      default:
        return tab;
    }
  }

  Future<void> _save() async {
    if (_enabledTabs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('少なくとも1つのタブを表示してください')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final sortedEnabledTabs =
          _tabOrder.where((tab) => _enabledTabs.contains(tab)).toList();

      final updated = UserPreference(
        enabledTabs: sortedEnabledTabs,
        tabOrder: List<String>.from(_tabOrder),
        initialTab: _initialTab,
        themeMode: _themeMode,
      );

      await context.read<PreferenceController>().updatePreferences(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定を保存しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}