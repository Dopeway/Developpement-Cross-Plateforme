import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/artisan.dart';
import 'package:quickfix_tunisia/core/models/artisan_catalog.dart';
import 'package:quickfix_tunisia/core/models/availability.dart';
import 'package:quickfix_tunisia/core/services/availability_calculator.dart';

void main() {
  const artisan = Artisan(
    id: 'artisan-1',
    name: 'Sami',
    trade: ArtisanTrade.plumber,
    area: InterventionArea.tunis,
    rating: 4.8,
    reviewCount: 12,
    startingPrice: 50,
    verified: true,
    availableToday: false,
    availabilityRules: [
      AvailabilityRule(
        weekday: DateTime.tuesday,
        startMinutes: 9 * 60,
        endMinutes: 12 * 60,
      ),
    ],
  );

  test(
    'trouve un créneau restant selon le planning, pas le booléen historique',
    () {
      final day = DateTime(2026, 11, 10);
      final now = DateTime(2026, 11, 10, 10, 15);

      expect(hasAvailableSlotOn(artisan: artisan, day: day, now: now), isTrue);
      expect(
        availableSlotsForArtisan(
          artisan: artisan,
          day: day,
          now: now,
        ).map((slot) => slot.start.hour),
        [11],
      );
    },
  );

  test('exclut une journée marquée indisponible', () {
    const absentArtisan = Artisan(
      id: 'artisan-2',
      name: 'Amel',
      trade: ArtisanTrade.electrician,
      area: InterventionArea.tunis,
      rating: 4.6,
      reviewCount: 8,
      startingPrice: 45,
      verified: true,
      availableToday: true,
      availabilityRules: [
        AvailabilityRule(
          weekday: DateTime.tuesday,
          startMinutes: 9 * 60,
          endMinutes: 17 * 60,
        ),
      ],
      availabilityExceptions: [
        AvailabilityException(date: '2026-11-10', unavailable: true),
      ],
    );

    expect(
      hasAvailableSlotOn(
        artisan: absentArtisan,
        day: DateTime(2026, 11, 10),
        now: DateTime(2026, 11, 10, 8),
      ),
      isFalse,
    );
  });
}
