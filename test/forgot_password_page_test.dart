import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/app/app_routes.dart';
import 'package:quickfix_tunisia/features/auth/presentation/forgot_password_page.dart';
import 'package:quickfix_tunisia/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('ouvre la page depuis la connexion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const LoginPage(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Mot de passe oublié ?'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordPage), findsOneWidget);
  });

  testWidgets('valide l’adresse et bloque les envois multiples', (
    tester,
  ) async {
    final pending = Completer<void>();
    final sentEmails = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordPage(
          onSend: (email) {
            sentEmails.add(email);
            return pending.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('Envoyer le lien'));
    await tester.pump();
    expect(find.text('Indiquez une adresse e-mail valide.'), findsOneWidget);
    expect(sentEmails, isEmpty);

    await tester.enterText(find.byType(TextFormField), '  client@example.tn  ');
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pump();
    expect(sentEmails, ['client@example.tn']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Si un compte correspond'), findsOneWidget);
  });

  testWidgets('masque l’absence de compte', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordPage(
          onSend: (_) async =>
              throw FirebaseAuthException(code: 'user-not-found'),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'client@example.tn');
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Si un compte correspond'), findsOneWidget);
  });

  testWidgets('signale une panne réseau et permet de réessayer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordPage(
          onSend: (_) async =>
              throw FirebaseAuthException(code: 'network-request-failed'),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'client@example.tn');
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Connexion indisponible'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
