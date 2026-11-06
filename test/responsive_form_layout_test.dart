import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/widgets/responsive_form_layout.dart';

void main() {
  testWidgets('limite la largeur du contenu sur un grand écran', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveFormLayout(child: Text('Contenu du formulaire')),
        ),
      ),
    );

    final constrainedBox = tester.widget<ConstrainedBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox && widget.constraints.maxWidth == 680,
      ),
    );

    expect(constrainedBox.constraints.maxWidth, 680);
    expect(find.byType(Card), findsOneWidget);
  });

  testWidgets('garde le formulaire sans carte sur mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveFormLayout(child: Text('Contenu du formulaire')),
        ),
      ),
    );

    expect(find.byType(Card), findsNothing);
  });

  testWidgets('adapte le formulaire aux largeurs de référence', (tester) async {
    for (final size in <Size>[
      const Size(360, 800),
      const Size(600, 900),
      const Size(840, 900),
      const Size(1024, 900),
      const Size(1440, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveFormLayout(child: Text('Contenu du formulaire')),
          ),
        ),
      );
      expect(
        find.byType(Card),
        size.width >= 720 ? findsOneWidget : findsNothing,
      );
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('reste défilable avec une police agrandie', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: ResponsiveFormLayout(
              child: Text(
                'Un contenu suffisamment long pour vérifier la lisibilité.',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ListView), findsOneWidget);
  });
}
