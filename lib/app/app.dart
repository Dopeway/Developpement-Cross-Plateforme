import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'app_theme.dart';
import '../core/state/app_controller.dart';
import '../core/state/app_scope.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/shell/presentation/app_shell.dart';

class QuickFixApp extends StatefulWidget {
  const QuickFixApp({super.key});

  @override
  State<QuickFixApp> createState() => _QuickFixAppState();
}

class _QuickFixAppState extends State<QuickFixApp> {
  late final AppController _controller = AppController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    controller: _controller,
    child: MaterialApp(
      title: 'QuickFix Tunisia',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AppGate(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    ),
  );
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    if (!controller.authResolved) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return controller.currentUser == null
        ? const LoginPage()
        : const AppShell();
  }
}
