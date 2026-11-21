import 'package:flutter/material.dart';

import '../core/models/artisan.dart';
import '../core/models/intervention_request.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/artisans/presentation/artisan_detail_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/chat/presentation/chat_page.dart';
import '../features/request/presentation/request_form_page.dart';
import '../features/request/presentation/request_details_page.dart';
import '../features/request/presentation/intervention_report_page.dart';
import '../features/request/presentation/billing_document_page.dart';
import '../features/shell/presentation/app_shell.dart';

abstract final class AppRoutes {
  static const login = '/';
  static const forgotPassword = '/mot-de-passe-oublie';
  static const home = '/accueil';
  static const artisanDetail = '/artisan';
  static const requestForm = '/demande';
  static const requestDetails = '/demande/details';
  static const chat = '/demande/discussion';
  static const interventionReport = '/demande/rapport';
  static const billingDocument = '/demande/facturation';
  static const admin = '/administration';
  static Route<void> onGenerateRoute(
    RouteSettings settings,
  ) => switch (settings.name) {
    home => MaterialPageRoute<void>(builder: (_) => const AppShell()),
    login => MaterialPageRoute<void>(builder: (_) => const LoginPage()),
    forgotPassword => MaterialPageRoute<void>(
      builder: (_) => const ForgotPasswordPage(),
    ),
    artisanDetail when settings.arguments is Artisan => MaterialPageRoute<void>(
      builder: (_) =>
          ArtisanDetailPage(artisan: settings.arguments! as Artisan),
    ),
    requestForm when settings.arguments is Artisan => MaterialPageRoute<void>(
      builder: (_) => RequestFormPage(artisan: settings.arguments! as Artisan),
    ),
    requestDetails when settings.arguments is InterventionRequest =>
      MaterialPageRoute<void>(
        builder: (_) => RequestDetailsPage(
          request: settings.arguments! as InterventionRequest,
        ),
      ),
    chat when settings.arguments is InterventionRequest =>
      MaterialPageRoute<void>(
        builder: (_) =>
            ChatPage(request: settings.arguments! as InterventionRequest),
      ),
    interventionReport when settings.arguments is InterventionRequest =>
      MaterialPageRoute<void>(
        builder: (_) => InterventionReportPage(
          request: settings.arguments! as InterventionRequest,
        ),
      ),
    billingDocument when settings.arguments is InterventionRequest =>
      MaterialPageRoute<void>(
        builder: (_) => BillingDocumentPage(
          request: settings.arguments! as InterventionRequest,
        ),
      ),
    admin => MaterialPageRoute<void>(builder: (_) => const AdminPage()),
    _ => MaterialPageRoute<void>(
      builder: (_) =>
          const Scaffold(body: Center(child: Text('Page introuvable.'))),
    ),
  };
}
