import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/artisan.dart';
import 'package:quickfix_tunisia/core/models/artisan_catalog.dart';
import 'package:quickfix_tunisia/features/availability/presentation/availability_page.dart';

void main() {
  testWidgets(
    'reste lisible sur un petit écran et enregistre les changements',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var saveCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvailabilityEditor(
              artisan: const Artisan(
                id: 'artisan-1',
                name: 'Sami',
                trade: ArtisanTrade.plumber,
                area: InterventionArea.tunis,
                rating: 4.8,
                reviewCount: 12,
                startingPrice: 50,
                verified: true,
                availableToday: true,
              ),
              onSave:
                  ({
                    required rules,
                    required exceptions,
                    required defaultDurationMinutes,
                  }) async {
                    saveCount++;
                  },
            ),
          ),
        ),
      );

      expect(find.text('Organisez vos disponibilités'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Lundi'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(Switch).first);
      await tester.scrollUntilVisible(
        find.text('Enregistrer le planning'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Enregistrer le planning'));
      await tester.pumpAndSettle();

      expect(saveCount, 1);
      expect(find.text('Planning enregistré.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
