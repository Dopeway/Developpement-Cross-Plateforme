import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'app_theme.dart';
import '../core/data/demo_repository.dart';
import '../core/state/demo_scope.dart';
import '../core/state/demo_store.dart';

class QuickFixApp extends StatefulWidget {
  const QuickFixApp({super.key});

  @override
  State<QuickFixApp> createState() => _QuickFixAppState();
}

class _QuickFixAppState extends State<QuickFixApp> {
  late final Future<DemoStore> _storeFuture = const DemoRepository()
      .load()
      .then(DemoStore.new);

  @override
  Widget build(BuildContext context) => FutureBuilder<DemoStore>(
    future: _storeFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: Center(
              child: Text('Impossible de charger la démonstration.'),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      return DemoScope(
        store: snapshot.data!,
        child: MaterialApp(
          title: 'QuickFix Tunisia',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          initialRoute: AppRoutes.login,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      );
    },
  );
}
