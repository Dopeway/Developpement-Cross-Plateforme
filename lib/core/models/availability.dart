class AvailabilityRule {
  const AvailabilityRule({
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
  });

  factory AvailabilityRule.fromJson(Map<String, Object?> json) =>
      AvailabilityRule(
        weekday: json['weekday']! as int,
        startMinutes: json['startMinutes']! as int,
        endMinutes: json['endMinutes']! as int,
      );

  final int weekday;
  final int startMinutes;
  final int endMinutes;

  Map<String, Object> toJson() => {
    'weekday': weekday,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
  };
}

class AvailabilityException {
  const AvailabilityException({required this.date, required this.unavailable});

  factory AvailabilityException.fromJson(Map<String, Object?> json) =>
      AvailabilityException(
        date: json['date']! as String,
        unavailable: json['unavailable']! as bool,
      );

  final String date;
  final bool unavailable;

  Map<String, Object> toJson() => {'date': date, 'unavailable': unavailable};
}
