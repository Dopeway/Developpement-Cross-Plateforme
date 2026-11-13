import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/booking_slot.dart';

void main() {
  test('détecte des créneaux qui se chevauchent', () {
    final first = BookingSlot(
      start: DateTime(2026, 11, 8, 9),
      end: DateTime(2026, 11, 8, 10),
      timeZone: 'Africa/Tunis',
    );
    final overlap = BookingSlot(
      start: DateTime(2026, 11, 8, 9, 30),
      end: DateTime(2026, 11, 8, 10, 30),
      timeZone: 'Africa/Tunis',
    );
    final next = BookingSlot(
      start: DateTime(2026, 11, 8, 10),
      end: DateTime(2026, 11, 8, 11),
      timeZone: 'Africa/Tunis',
    );

    expect(first.overlaps(overlap), isTrue);
    expect(first.overlaps(next), isFalse);
  });

  test('désérialise les dates ISO renvoyées par une Cloud Function', () {
    final slot = BookingSlot.fromJson(const <String, Object?>{
      'start': '2026-11-08T08:00:00.000Z',
      'end': '2026-11-08T09:00:00.000Z',
      'timeZone': 'Africa/Tunis',
    });

    expect(slot.start.toUtc(), DateTime.utc(2026, 11, 8, 8));
    expect(slot.durationMinutes, 60);
  });
}
