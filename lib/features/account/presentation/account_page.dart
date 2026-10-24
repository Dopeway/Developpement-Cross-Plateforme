import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/state/demo_scope.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final user = store.currentUser!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 32)),
        const SizedBox(height: 12),
        Center(
          child: Text(user.name, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 24),
        const ListTile(
          leading: Icon(Icons.person_outline),
          title: Text('Informations personnelles'),
          trailing: Icon(Icons.chevron_right),
        ),
        const ListTile(
          leading: Icon(Icons.location_on_outlined),
          title: Text('Mes adresses'),
          trailing: Icon(Icons.chevron_right),
        ),
        const ListTile(
          leading: Icon(Icons.help_outline),
          title: Text('Aide et sécurité'),
          trailing: Icon(Icons.chevron_right),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.admin_panel_settings_outlined),
          title: const Text('Aperçu administration'),
          subtitle: const Text('Démonstration du rôle administrateur'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, AppRoutes.admin),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Se déconnecter'),
          onTap: () {
            store.logout();
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (_) => false,
            );
          },
        ),
      ],
    );
  }
}
