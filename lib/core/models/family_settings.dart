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

  /// Bump when the privacy summary a parent agrees to at sign-up changes.
  static const currentConsentVersion = '2026-09';

  /// Time zones offered in settings and learner setup. The database accepts
  /// any IANA name; these just cover Curio's families so far.
  static const commonTimezones = [
    'UTC',
    'Asia/Kolkata',
    'Asia/Dubai',
    'Asia/Singapore',
    'Asia/Tokyo',
    'Europe/London',
    'Europe/Paris',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'Australia/Sydney',
    'Pacific/Auckland',
  ];

  /// Best guess at this device's zone from [commonTimezones]. Flutter only
  /// exposes an abbreviation ("IST", "Pacific Daylight Time") and an
  /// offset, so match the name first and fall back to the offset.
  static String guessTimezone({String? name, Duration? offset}) {
    final now = DateTime.now();
    final zoneName = (name ?? now.timeZoneName).toLowerCase();
    final zoneOffset = offset ?? now.timeZoneOffset;
    // Most specific phrases first: "Australian Eastern" must win over
    // "Eastern", "Central European" over "Central".
    const byName = {
      'australian eastern': 'Australia/Sydney',
      'new zealand': 'Pacific/Auckland',
      'central european': 'Europe/Paris',
      'india': 'Asia/Kolkata',
      'ist': 'Asia/Kolkata',
      'gulf': 'Asia/Dubai',
      'singapore': 'Asia/Singapore',
      'japan': 'Asia/Tokyo',
      'jst': 'Asia/Tokyo',
      'british': 'Europe/London',
      'bst': 'Europe/London',
      'greenwich': 'Europe/London',
      'cet': 'Europe/Paris',
      'cest': 'Europe/Paris',
      'eastern': 'America/New_York',
      'est': 'America/New_York',
      'edt': 'America/New_York',
      'central': 'America/Chicago',
      'cst': 'America/Chicago',
      'cdt': 'America/Chicago',
      'mountain': 'America/Denver',
      'mst': 'America/Denver',
      'mdt': 'America/Denver',
      'pacific': 'America/Los_Angeles',
      'pst': 'America/Los_Angeles',
      'pdt': 'America/Los_Angeles',
      'aest': 'Australia/Sydney',
      'aedt': 'Australia/Sydney',
      'nzst': 'Pacific/Auckland',
      'nzdt': 'Pacific/Auckland',
    };
    for (final MapEntry(:key, :value) in byName.entries) {
      final whole = key.length <= 4 ? zoneName == key : zoneName.contains(key);
      if (whole) return value;
    }
    const byOffset = {
      330: 'Asia/Kolkata',
      240: 'Asia/Dubai',
      480: 'Asia/Singapore',
      540: 'Asia/Tokyo',
      0: 'Europe/London',
      60: 'Europe/Paris',
      -300: 'America/New_York',
      -360: 'America/Chicago',
      -420: 'America/Denver',
      -480: 'America/Los_Angeles',
      600: 'Australia/Sydney',
      660: 'Australia/Sydney',
      720: 'Pacific/Auckland',
      780: 'Pacific/Auckland',
    };
    return byOffset[zoneOffset.inMinutes] ?? 'UTC';
  }

  factory FamilySettings.fromJson(Map<String, dynamic> json) => FamilySettings(
    dailyGoal: json['daily_goal'] as int? ?? 3,
    remindersEnabled: json['reminders_enabled'] == true,
    reminderHour: json['reminder_hour'] as int? ?? 18,
    timezone: json['timezone'] as String? ?? 'UTC',
    weeklyEmailEnabled: json['weekly_email_enabled'] == true,
    consentVersion: json['consent_version'] as String?,
  );
  FamilySettings copyWith({String? consentVersion}) => FamilySettings(
    dailyGoal: dailyGoal,
    remindersEnabled: remindersEnabled,
    reminderHour: reminderHour,
    timezone: timezone,
    weeklyEmailEnabled: weeklyEmailEnabled,
    consentVersion: consentVersion ?? this.consentVersion,
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
