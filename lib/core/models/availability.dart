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

  bool get isValid =>
      weekday >= DateTime.monday &&
      weekday <= DateTime.sunday &&
      startMinutes >= 0 &&
      endMinutes <= Duration.minutesPerDay &&
      startMinutes < endMinutes;

  bool overlaps(AvailabilityRule other) =>
      weekday == other.weekday &&
      startMinutes < other.endMinutes &&
      endMinutes > other.startMinutes;

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

  DateTime? get parsedDate => DateTime.tryParse(date);

  Map<String, Object> toJson() => {'date': date, 'unavailable': unavailable};
}
