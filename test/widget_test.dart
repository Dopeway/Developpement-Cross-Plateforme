import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/app/app.dart';

void main() {
  testWidgets('affiche les comptes de démonstration', (tester) async {
    await tester.pumpWidget(const QuickFixApp());
    await tester.pumpAndSettle();

    expect(find.text('Client — Amira Khalfallah'), findsOneWidget);
    expect(find.text('Artisan — Sami Ben Salem'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
