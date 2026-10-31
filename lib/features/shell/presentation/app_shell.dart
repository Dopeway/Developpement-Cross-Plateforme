import 'package:flutter/material.dart';

import '../../account/presentation/account_page.dart';
import '../../admin/presentation/admin_page.dart';
import '../../activity/presentation/activity_page.dart';
import '../../home/presentation/home_page.dart';
import '../../request/presentation/requests_page.dart';
import '../../../core/models/app_user.dart';
import '../../../core/state/app_scope.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).currentUser!.role;
    final pages = switch (role) {
      UserRole.client => const <Widget>[
        HomePage(),
        RequestsPage(),
        AccountPage(),
      ],
      UserRole.artisan => const <Widget>[
        ActivityPage(),
        RequestsPage(),
        AccountPage(),
      ],
      UserRole.admin => const <Widget>[
        AdminPage(embedded: true),
        RequestsPage(),
        AccountPage(),
      ],
    };
    final titles = switch (role) {
      UserRole.client => const ['QuickFix', 'Mes demandes', 'Mon compte'],
      UserRole.artisan => const [
        'Espace artisan',
        'Mes interventions',
        'Mon compte',
      ],
      UserRole.admin => const [
        'Administration',
        'Toutes les demandes',
        'Mon compte',
      ],
    };
    if (_selectedIndex >= pages.length) _selectedIndex = 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Aucune nouvelle notification.')),
            ),
            icon: const Badge(child: Icon(Icons.notifications_outlined)),
          ),
        ],
      ),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) =>
            setState(() => _selectedIndex = value),
        destinations: [
          NavigationDestination(
            icon: Icon(
              role == UserRole.client
                  ? Icons.home_outlined
                  : Icons.handyman_outlined,
            ),
            selectedIcon: Icon(
              role == UserRole.client ? Icons.home : Icons.handyman,
            ),
            label: role == UserRole.client ? 'Accueil' : 'Activité',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Demandes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Compte',
          ),
        ],
      ),
    );
  }
}
