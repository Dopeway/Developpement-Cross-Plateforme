import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/artisan.dart';
import 'package:quickfix_tunisia/core/models/artisan_catalog.dart';
import 'package:quickfix_tunisia/core/models/availability.dart';

void main() {
  test('détecte deux plages du même jour qui se chevauchent', () {
    const morning = AvailabilityRule(
      weekday: DateTime.monday,
      startMinutes: 8 * 60,
      endMinutes: 12 * 60,
    );
    const overlap = AvailabilityRule(
      weekday: DateTime.monday,
      startMinutes: 11 * 60,
      endMinutes: 14 * 60,
    );
    const afternoon = AvailabilityRule(
      weekday: DateTime.monday,
      startMinutes: 14 * 60,
      endMinutes: 18 * 60,
    );

    expect(morning.isValid, isTrue);
    expect(morning.overlaps(overlap), isTrue);
    expect(morning.overlaps(afternoon), isFalse);
  });

  test('sérialise le planning complet d’un artisan', () {
    const artisan = Artisan(
      id: 'artisan-1',
      name: 'Sami',
      trade: ArtisanTrade.plumber,
      area: InterventionArea.tunis,
      rating: 4.8,
      reviewCount: 12,
      startingPrice: 50,
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
      defaultDurationMinutes: 90,
    );

    final parsed = Artisan.fromJson(<String, Object?>{
      'id': artisan.id,
      ...artisan.toJson(),
    });

    expect(parsed.availabilityRules, hasLength(1));
    expect(parsed.availabilityRules.single.weekday, DateTime.tuesday);
    expect(parsed.availabilityExceptions.single.date, '2026-11-10');
    expect(parsed.defaultDurationMinutes, 90);
  });
}
