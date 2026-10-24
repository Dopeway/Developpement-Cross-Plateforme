import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, this.embedded = false});
  final bool embedded;
  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Vue de supervision',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Stat(
              label: 'Demandes en attente',
              value: '12',
              icon: Icons.assignment_late_outlined,
            ),
            _Stat(
              label: 'Artisans à valider',
              value: '4',
              icon: Icons.verified_user_outlined,
            ),
            _Stat(
              label: 'Signalements ouverts',
              value: '2',
              icon: Icons.flag_outlined,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('À traiter', style: Theme.of(context).textTheme.titleLarge),
        Card(
          child: ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Profil de Walid M.'),
            subtitle: const Text('Électricien · justificatifs en attente'),
            trailing: FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil ouvert pour vérification (démo).'),
                ),
              ),
              child: const Text('Examiner'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Signalement #S-204'),
            subtitle: const Text('Avis à modérer'),
            trailing: OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signalement ouvert pour modération (démo).'),
                ),
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ],
    );
    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: content,
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 18),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    ),
  );
}
