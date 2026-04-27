class UserPreference {
  final List<String> enabledTabs;
  final List<String> tabOrder;
  final String initialTab;
  final String themeMode;

  UserPreference({
    required this.enabledTabs,
    required this.tabOrder,
    required this.initialTab,
    required this.themeMode,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      enabledTabs: List<String>.from(json['enabled_tabs'] ?? []),
      tabOrder: List<String>.from(json['tab_order'] ?? []),
      initialTab: json['initial_tab'] as String? ?? 'calendar',
      themeMode: json['theme_mode'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled_tabs': enabledTabs,
      'tab_order': tabOrder,
      'initial_tab': initialTab,
      'theme_mode': themeMode,
    };
  }

  UserPreference copyWith({
    List<String>? enabledTabs,
    List<String>? tabOrder,
    String? initialTab,
    String? themeMode,
  }) {
    return UserPreference(
      enabledTabs: enabledTabs ?? this.enabledTabs,
      tabOrder: tabOrder ?? this.tabOrder,
      initialTab: initialTab ?? this.initialTab,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}