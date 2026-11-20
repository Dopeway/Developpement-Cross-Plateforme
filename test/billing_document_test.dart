import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/billing_document.dart';
import 'package:quickfix_tunisia/features/request/data/billing_pdf_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const document = BillingDocument(
    requestId: 'request-1',
    artisanId: 'artisan-1',
    clientId: 'client-1',
    issuerName: 'Atelier Sami',
    issuerAddress: '12 rue des Jasmins, Tunis',
    taxId: '1234567/A/M/000',
    vatRate: 19,
    clientName: 'Amira Khalfallah',
    clientAddress: '4 rue des Oliviers, Tunis',
    service: 'Plomberie',
    workPerformed: 'Remplacement du joint et contrôle de l’étanchéité.',
    serviceDate: '2026-11-19T14:00:00.000',
    totalMillimes: 119000,
  );

  test('calcule HT et TVA sans modifier le devis TTC', () {
    expect(document.subtotalMillimes, 100000);
    expect(document.vatMillimes, 19000);
    expect(
      document.subtotalMillimes + document.vatMillimes,
      document.totalMillimes,
    );
    expect(
      BillingDocument.fromJson(document.toJson()).totalMillimes,
      document.totalMillimes,
    );
  });

  test('génère un PDF A4 utilisable à partir des données du dossier', () async {
    final bytes = await const BillingPdfBuilder().build(document);
    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.sublist(0, 4)), '%PDF');
  });
}
