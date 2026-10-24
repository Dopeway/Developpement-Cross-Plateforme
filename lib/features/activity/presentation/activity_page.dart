import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/intervention_request.dart';
import '../../../core/state/demo_scope.dart';
import '../../admin/presentation/admin_page.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    if (store.currentUser!.role == UserRole.admin) {
      return const AdminPage(embedded: true);
    }
    final pending = store
        .requestsForCurrentUser()
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
                          onPressed: () {
                            store.updateRequestStatus(
                              request.id,
                              RequestStatus.refused,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Demande refusée.')),
                            );
                          },
                          child: const Text('Refuser'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            store.updateRequestStatus(
                              request.id,
                              RequestStatus.accepted,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Demande acceptée.'),
                              ),
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
        const ListTile(
          leading: Icon(Icons.verified_outlined),
          title: Text('Profil vérifié'),
          subtitle: Text('Vos justificatifs ont été validés.'),
        ),
        const ListTile(
          leading: Icon(Icons.calendar_month_outlined),
          title: Text('Disponibilités'),
          subtitle: Text('Gérez vos créneaux et indisponibilités.'),
        ),
      ],
    );
  }
}
