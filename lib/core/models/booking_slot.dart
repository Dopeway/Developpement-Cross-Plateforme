import 'package:cloud_firestore/cloud_firestore.dart';

class BookingSlot {
  const BookingSlot({
    required this.start,
    required this.end,
    required this.timeZone,
    this.expiresAt,
  });

  factory BookingSlot.fromJson(Map<String, Object?> json) => BookingSlot(
    start: _date(json['start'])!,
    end: _date(json['end'])!,
    timeZone: json['timeZone'] as String? ?? 'Africa/Tunis',
    expiresAt: _date(json['expiresAt']),
  );

  final DateTime start;
  final DateTime end;
  final String timeZone;
  final DateTime? expiresAt;

  int get durationMinutes => end.difference(start).inMinutes;
  bool overlaps(BookingSlot other) =>
      start.isBefore(other.end) && end.isAfter(other.start);

  Map<String, Object> toJson() => {
    'start': Timestamp.fromDate(start),
    'end': Timestamp.fromDate(end),
    'timeZone': timeZone,
    if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
  };

  static DateTime? _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime dateTime => dateTime,
    _ => null,
  };
}
