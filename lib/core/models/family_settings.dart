class FamilySettings {
  const FamilySettings({
    this.dailyGoal = 3,
    this.remindersEnabled = false,
    this.reminderHour = 18,
    this.timezone = 'UTC',
    this.weeklyEmailEnabled = false,
    this.consentVersion,
  });
  final int dailyGoal;
  final bool remindersEnabled;
  final int reminderHour;
  final String timezone;
  final bool weeklyEmailEnabled;
  final String? consentVersion;
  factory FamilySettings.fromJson(Map<String, dynamic> json) => FamilySettings(
    dailyGoal: json['daily_goal'] as int? ?? 3,
    remindersEnabled: json['reminders_enabled'] == true,
    reminderHour: json['reminder_hour'] as int? ?? 18,
    timezone: json['timezone'] as String? ?? 'UTC',
    weeklyEmailEnabled: json['weekly_email_enabled'] == true,
    consentVersion: json['consent_version'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'daily_goal': dailyGoal,
    'reminders_enabled': remindersEnabled,
    'reminder_hour': reminderHour,
    'timezone': timezone,
    'weekly_email_enabled': weeklyEmailEnabled,
    'consent_version': consentVersion,
  };
}
