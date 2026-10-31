import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/models/app_user.dart';
import '../../../core/state/app_scope.dart';
import 'account_section_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.currentUser!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 32)),
        const SizedBox(height: 12),
        Center(
          child: Text(user.name, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 4),
        Center(child: Text(user.role.label)),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Informations personnelles'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openSection(context, AccountSection.personal),
        ),
        if (user.role == UserRole.client)
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Mes adresses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openSection(context, AccountSection.addresses),
          ),
        if (user.role == UserRole.artisan)
          const ListTile(
            leading: Icon(Icons.work_outline),
            title: Text('Mon activité professionnelle'),
            subtitle: Text('Gérez votre profil depuis votre tableau de bord.'),
          ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Aide et sécurité'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openSection(context, AccountSection.help),
        ),
        if (user.role == UserRole.admin) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Administration'),
            subtitle: const Text('Gérer les validations et les demandes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.admin),
          ),
        ],
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Se déconnecter'),
          onTap: () async {
            await controller.logout();
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
      ],
    );
  }

  void _openSection(BuildContext context, AccountSection section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountSectionPage(section: section),
      ),
    );
  }
}
