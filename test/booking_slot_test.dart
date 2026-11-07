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
}
