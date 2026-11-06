import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/app_user.dart';
import 'package:quickfix_tunisia/core/models/artisan_catalog.dart';
import 'package:quickfix_tunisia/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('demande un métier et une zone sélectionnés pour un artisan', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

    final roleField = tester.widget<DropdownButtonFormField<UserRole>>(
      find.byType(DropdownButtonFormField<UserRole>),
    );
    roleField.onChanged!(UserRole.artisan);
    await tester.pump();

    expect(find.byType(DropdownButtonFormField<ArtisanTrade>), findsOneWidget);
    expect(
      find.byType(DropdownButtonFormField<InterventionArea>),
      findsOneWidget,
    );

    final tradeField = tester.widget<DropdownButtonFormField<ArtisanTrade>>(
      find.byType(DropdownButtonFormField<ArtisanTrade>),
    );
    final areaField = tester.widget<DropdownButtonFormField<InterventionArea>>(
      find.byType(DropdownButtonFormField<InterventionArea>),
    );

    expect(tradeField.validator!(null), 'Choisissez votre métier.');
    expect(areaField.validator!(null), 'Choisissez votre zone d’intervention.');
  });
}
