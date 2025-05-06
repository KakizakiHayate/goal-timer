class Settings {
  final String id;
  final String theme;
  final bool notificationsEnabled;
  final int reminderInterval;
  final bool soundEnabled;
  final int defaultTimerDuration;

  Settings({
    required this.id,
    required this.theme,
    required this.notificationsEnabled,
    required this.reminderInterval,
    required this.soundEnabled,
    required this.defaultTimerDuration,
  });

  factory Settings.defaultSettings() {
    return Settings(
      id: 'default',
      theme: 'system',
      notificationsEnabled: true,
      reminderInterval: 30,
      soundEnabled: true,
      defaultTimerDuration: 25,
    );
  }

  Settings copyWith({
    String? id,
    String? theme,
    bool? notificationsEnabled,
    int? reminderInterval,
    bool? soundEnabled,
    int? defaultTimerDuration,
  }) {
    return Settings(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderInterval: reminderInterval ?? this.reminderInterval,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      defaultTimerDuration: defaultTimerDuration ?? this.defaultTimerDuration,
    );
  }
}
