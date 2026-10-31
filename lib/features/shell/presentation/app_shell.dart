import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/state/app_scope.dart';
import '../../account/presentation/account_page.dart';
import '../../activity/presentation/activity_page.dart';
import '../../admin/presentation/admin_page.dart';
import '../../home/presentation/home_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../request/presentation/requests_page.dart';

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
    final destinations = _destinationsFor(role);
    final pages = _pagesFor(role);
    final isExpanded = MediaQuery.sizeOf(context).width >= 800;
    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(destinations[_selectedIndex].label),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 12),
                child: NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                      )
                      .toList(),
                ),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: pages[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isExpanded
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              destinations: destinations
                  .map(
                    (destination) => NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.82,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Notifications'),
            actions: [
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          body: const NotificationsPage(),
        ),
      ),
    );
  }

  List<Widget> _pagesFor(UserRole role) => switch (role) {
    UserRole.client => const [HomePage(), RequestsPage(), AccountPage()],
    UserRole.artisan => const [ActivityPage(), RequestsPage(), AccountPage()],
    UserRole.admin => const [
      AdminPage(embedded: true),
      RequestsPage(),
      AccountPage(),
    ],
  };

  List<_ShellDestination> _destinationsFor(UserRole role) => switch (role) {
    UserRole.client => const [
      _ShellDestination(Icons.home_outlined, Icons.home, 'Accueil'),
      _ShellDestination(
        Icons.assignment_outlined,
        Icons.assignment,
        'Demandes',
      ),
      _ShellDestination(Icons.person_outline, Icons.person, 'Compte'),
    ],
    UserRole.artisan => const [
      _ShellDestination(
        Icons.handyman_outlined,
        Icons.handyman,
        'Tableau de bord',
      ),
      _ShellDestination(
        Icons.assignment_outlined,
        Icons.assignment,
        'Interventions',
      ),
      _ShellDestination(Icons.person_outline, Icons.person, 'Compte'),
    ],
    UserRole.admin => const [
      _ShellDestination(
        Icons.dashboard_outlined,
        Icons.dashboard,
        'Supervision',
      ),
      _ShellDestination(
        Icons.assignment_outlined,
        Icons.assignment,
        'Demandes',
      ),
      _ShellDestination(Icons.person_outline, Icons.person, 'Compte'),
    ],
  };
}

class _ShellDestination {
  const _ShellDestination(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
