import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/artisan.dart';
import '../../../core/models/intervention_request.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/state/app_scope.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).currentUser;
    if (user == null || user.role != UserRole.admin) {
      return const Scaffold(body: Center(child: Text('Accès non autorisé.')));
    }

    final content = const _AdminContent();
    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: SafeArea(child: content),
    );
  }
}

class _AdminContent extends StatelessWidget {
  const _AdminContent();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return StreamBuilder<List<InterventionRequest>>(
      stream: controller.requests,
      builder: (context, requestsSnapshot) {
        if (requestsSnapshot.hasError) {
          return const Center(
            child: Text('Impossible de charger les données.'),
          );
        }
        return StreamBuilder<List<Artisan>>(
          stream: controller.pendingArtisans,
          builder: (context, artisansSnapshot) {
            if (artisansSnapshot.hasError) {
              return const Center(
                child: Text('Impossible de charger les artisans à examiner.'),
              );
            }
            if (!requestsSnapshot.hasData || !artisansSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _DashboardBody(
              requests: requestsSnapshot.data!,
              pendingArtisans: artisansSnapshot.data!,
              controller: controller,
            );
          },
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.requests,
    required this.pendingArtisans,
    required this.controller,
  });

  final List<InterventionRequest> requests;
  final List<Artisan> pendingArtisans;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final pendingRequests = requests
        .where((request) => request.status == RequestStatus.pending)
        .length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Vue de supervision',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Les chiffres sont synchronisés avec Cloud Firestore.'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Stat(
              label: 'Demandes en attente',
              value: '$pendingRequests',
              icon: Icons.assignment_late_outlined,
            ),
            _Stat(
              label: 'Artisans à valider',
              value: '${pendingArtisans.length}',
              icon: Icons.verified_user_outlined,
            ),
            _Stat(
              label: 'Demandes totales',
              value: '${requests.length}',
              icon: Icons.analytics_outlined,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Artisans à examiner',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (pendingArtisans.isEmpty)
          const Card(child: ListTile(title: Text('Aucun artisan en attente.'))),
        ...pendingArtisans.map(
          (artisan) => Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(artisan.name),
              subtitle: Text('${artisan.trade} · ${artisan.area}'),
              trailing: FilledButton(
                onPressed: () => _verify(context, artisan),
                child: const Text('Valider'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Demandes récentes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (requests.isEmpty)
          const Card(
            child: ListTile(title: Text('Aucune demande enregistrée.')),
          ),
        ...requests
            .take(5)
            .map(
              (request) => Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text(request.service),
                  subtitle: Text(
                    '${request.clientName} · ${request.status.label}',
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _verify(BuildContext context, Artisan artisan) async {
    try {
      await controller.verifyArtisan(artisan.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${artisan.name} a été validé.')),
        );
      }
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Validation impossible.')));
      }
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    ),
  );
}
