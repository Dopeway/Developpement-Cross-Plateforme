import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/intervention_request.dart';
import 'package:quickfix_tunisia/core/models/intervention_report.dart';
import 'package:quickfix_tunisia/features/request/presentation/request_details_page.dart';

void main() {
  testWidgets('affiche les informations d’une demande', (tester) async {
    const request = InterventionRequest(
      id: 'request-1',
      service: 'Plomberie',
      artisanId: 'artisan-1',
      artisanName: 'Mehdi Artisan',
      clientId: 'client-1',
      clientName: 'Amira Cliente',
      description: 'Fuite sous l’évier de la cuisine.',
      address: 'Menzah 5',
      date: 'Aujourd’hui · 16:00',
      status: RequestStatus.accepted,
    );

    await tester.pumpWidget(
      const MaterialApp(home: RequestDetailsPage(request: request)),
    );

    expect(find.text('Détail de la demande'), findsOneWidget);
    expect(find.text('Mehdi Artisan'), findsOneWidget);
    expect(find.text('Fuite sous l’évier de la cuisine.'), findsOneWidget);
    expect(find.text('Intervention confirmée'), findsWidgets);
  });

  testWidgets('propose le récapitulatif après une intervention terminée', (
    tester,
  ) async {
    const request = InterventionRequest(
      id: 'request-2',
      service: 'Électricité',
      artisanId: 'artisan-1',
      artisanName: 'Mehdi Artisan',
      clientId: 'client-1',
      clientName: 'Amira Cliente',
      description: 'Prise à réparer.',
      address: 'Menzah 5',
      date: 'Aujourd’hui · 16:00',
      status: RequestStatus.completed,
      interventionReport: InterventionReport(
        workPerformed: 'Prise remplacée et installation vérifiée.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          builder: (_) => RequestDetailsPage(request: request),
        ),
        home: RequestDetailsPage(request: request),
      ),
    );

    await tester.scrollUntilVisible(
      find.textContaining('Consulter le rapport'),
      200,
    );
    expect(find.textContaining('Consulter le rapport'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Consulter le projet de facture'),
      200,
    );
    expect(find.text('Consulter le projet de facture'), findsOneWidget);
  });
}
