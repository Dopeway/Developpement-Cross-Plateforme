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
}
