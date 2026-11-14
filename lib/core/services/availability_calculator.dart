import '../models/artisan.dart';
import '../models/availability.dart';
import '../models/booking_slot.dart';

List<BookingSlot> availableSlotsForArtisan({
  required Artisan artisan,
  required DateTime day,
  DateTime? now,
}) {
  final dateKey = _dateKey(day);
  if (artisan.availabilityExceptions.any(
    (exception) => exception.date == dateKey && exception.unavailable,
  )) {
    return const [];
  }

  final rules = artisan.availabilityRules.isEmpty
      ? [
          AvailabilityRule(
            weekday: day.weekday,
            startMinutes: 9 * 60,
            endMinutes: 17 * 60,
          ),
        ]
      : artisan.availabilityRules.where((rule) => rule.weekday == day.weekday);
  final duration = artisan.defaultDurationMinutes.clamp(15, 240).toInt();
  final referenceTime = now ?? DateTime.now();
  final slots = <BookingSlot>[];

  for (final rule in rules) {
    for (
      var minute = rule.startMinutes;
      minute + duration <= rule.endMinutes;
      minute += duration
    ) {
      final start = DateTime(
        day.year,
        day.month,
        day.day,
      ).add(Duration(minutes: minute));
      if (!start.isAfter(referenceTime)) continue;
      slots.add(
        BookingSlot(
          start: start,
          end: start.add(Duration(minutes: duration)),
          timeZone: 'Africa/Tunis',
        ),
      );
    }
  }

  return slots;
}

bool hasAvailableSlotOn({
  required Artisan artisan,
  required DateTime day,
  DateTime? now,
}) => availableSlotsForArtisan(artisan: artisan, day: day, now: now).isNotEmpty;

String _dateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
