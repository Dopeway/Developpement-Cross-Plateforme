import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/artisan.dart';
import 'package:quickfix_tunisia/core/models/artisan_catalog.dart';
import 'package:quickfix_tunisia/core/models/availability.dart';
import 'package:quickfix_tunisia/features/home/presentation/home_page.dart';

void main() {
  test('filtre les artisans par ville', () {
    final artisans = [
      _artisan(id: 'tunis', area: InterventionArea.tunis),
      _artisan(id: 'sfax', area: InterventionArea.sfax),
    ];

    final filtered = filterArtisans(
      artisans: artisans,
      query: '',
      area: InterventionArea.sfax,
      availableOnly: false,
    );

    expect(filtered.map((artisan) => artisan.id), ['sfax']);
  });

  test('combine le métier, le planning et la recherche', () {
    final now = DateTime(2026, 11, 10, 10);
    final artisans = [
      _artisan(
        id: 'plombier-disponible',
        area: InterventionArea.tunis,
        trade: ArtisanTrade.plumber,
        availableToday: false,
        availabilityRules: const [
          AvailabilityRule(
            weekday: DateTime.tuesday,
            startMinutes: 11 * 60,
            endMinutes: 12 * 60,
          ),
        ],
      ),
      _artisan(
        id: 'electricien-disponible',
        area: InterventionArea.tunis,
        trade: ArtisanTrade.electrician,
        availabilityRules: const [
          AvailabilityRule(
            weekday: DateTime.tuesday,
            startMinutes: 11 * 60,
            endMinutes: 12 * 60,
          ),
        ],
      ),
      _artisan(
        id: 'plombier-indisponible',
        area: InterventionArea.tunis,
        trade: ArtisanTrade.plumber,
        availableToday: false,
        availabilityRules: const [
          AvailabilityRule(
            weekday: DateTime.tuesday,
            startMinutes: 11 * 60,
            endMinutes: 12 * 60,
          ),
        ],
        availabilityExceptions: const [
          AvailabilityException(date: '2026-11-10', unavailable: true),
        ],
      ),
    ];

    final filtered = filterArtisans(
      artisans: artisans,
      query: 'plombier',
      trade: ArtisanTrade.plumber,
      availableOnly: true,
      now: now,
    );

    expect(filtered.map((artisan) => artisan.id), ['plombier-disponible']);
  });
}

Artisan _artisan({
  required String id,
  required InterventionArea area,
  ArtisanTrade trade = ArtisanTrade.plumber,
  bool availableToday = true,
  List<AvailabilityRule> availabilityRules = const [],
  List<AvailabilityException> availabilityExceptions = const [],
}) => Artisan(
  id: id,
  name: 'Artisan $id',
  trade: trade,
  area: area,
  rating: 4.5,
  reviewCount: 10,
  startingPrice: 40,
  verified: true,
  availableToday: availableToday,
  availabilityRules: availabilityRules,
  availabilityExceptions: availabilityExceptions,
);
