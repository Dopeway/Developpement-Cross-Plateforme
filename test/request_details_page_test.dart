import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/intervention_request.dart';
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
    expect(find.text('Acceptée'), findsWidgets);
  });
}
