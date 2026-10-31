import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/artisan.dart';
import '../../../core/models/intervention_request.dart';
import '../../../core/state/app_scope.dart';
import '../../admin/presentation/admin_page.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    if (controller.currentUser!.role == UserRole.admin) {
      return const AdminPage(embedded: true);
    }
    return StreamBuilder<Artisan?>(
      stream: controller.artisanProfile,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Impossible de charger le profil artisan.'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == null) {
          return const Center(
            child: Text('Votre profil artisan est introuvable.'),
          );
        }
        return StreamBuilder<List<InterventionRequest>>(
          stream: controller.requests,
          builder: (context, requestsSnapshot) {
            if (requestsSnapshot.hasError) {
              return const Center(
                child: Text('Impossible de charger les demandes.'),
              );
            }
            if (!requestsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildContent(
              context,
              requestsSnapshot.data!,
              isVerified: snapshot.data!.verified,
            );
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<InterventionRequest> requests, {
    required bool isVerified,
  }) {
    final pending = requests
        .where((request) => request.status == RequestStatus.pending)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Espace artisan',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Aperçu préparatoire du parcours professionnel.'),
        const SizedBox(height: 20),
        if (pending.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune nouvelle demande à traiter.'),
            ),
          ),
        ...pending.map(
          (request) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.service,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${request.description}\nClient : ${request.clientName}\n${request.address}\n${request.date}',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await _updateStatus(
                              context,
                              request.id,
                              RequestStatus.refused,
                              'Demande refusée.',
                            );
                          },
                          child: const Text('Refuser'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            await _updateStatus(
                              context,
                              request.id,
                              RequestStatus.accepted,
                              'Demande acceptée.',
                            );
                          },
                          child: const Text('Accepter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: Icon(
            isVerified
                ? Icons.verified_outlined
                : Icons.pending_actions_outlined,
          ),
          title: Text(
            isVerified ? 'Profil vérifié' : 'Profil en cours de validation',
          ),
          subtitle: Text(
            isVerified ? 'Vos justificatifs ont été validés.' : 'L’administration examinera votre profil avant sa mise en avant.',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.calendar_month_outlined),
          title: Text('Disponibilités'),
          subtitle: Text('Gérez vos créneaux et indisponibilités.'),
        ),
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    String requestId,
    RequestStatus status,
    String successMessage,
  ) async {
    try {
      await AppScope.of(context).updateRequestStatus(requestId, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La mise à jour a échoué.')),
        );
      }
    }
  }
}
