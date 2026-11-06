import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/artisan.dart';
import '../../../core/models/intervention_request.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/request_status_widgets.dart';

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

class _AdminContent extends StatefulWidget {
  const _AdminContent();

  @override
  State<_AdminContent> createState() => _AdminContentState();
}

class _AdminContentState extends State<_AdminContent> {
  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return StreamBuilder<List<InterventionRequest>>(
      stream: controller.requests,
      builder: (context, requestSnapshot) => StreamBuilder<List<Artisan>>(
        stream: controller.pendingArtisans,
        builder: (context, artisanSnapshot) => StreamBuilder<List<AppUser>>(
          stream: controller.users,
          builder: (context, userSnapshot) {
            if (requestSnapshot.hasError ||
                artisanSnapshot.hasError ||
                userSnapshot.hasError) {
              return ErrorStateView(
                message: 'Impossible de charger les données.',
                onRetry: () => setState(() {}),
              );
            }
            if (!requestSnapshot.hasData ||
                !artisanSnapshot.hasData ||
                !userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _DashboardBody(
              requests: requestSnapshot.data!,
              pendingArtisans: artisanSnapshot.data!,
              users: userSnapshot.data!,
            );
          },
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.requests,
    required this.pendingArtisans,
    required this.users,
  });

  final List<InterventionRequest> requests;
  final List<Artisan> pendingArtisans;
  final List<AppUser> users;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final pendingRequests = requests
        .where((r) => r.status == RequestStatus.pending)
        .length;
    final inProgress = requests
        .where((r) => r.status == RequestStatus.inProgress)
        .length;
    final completed = requests
        .where((r) => r.status == RequestStatus.completed)
        .length;
    final recentRequests = requests;
    var requestQuery = '';
    RequestStatus? requestStatus;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final filteredRequests = recentRequests.where((request) {
          final query = requestQuery.toLowerCase();
          final matchesQuery =
              query.isEmpty ||
              request.service.toLowerCase().contains(query) ||
              request.clientName.toLowerCase().contains(query) ||
              request.artisanName.toLowerCase().contains(query);
          return matchesQuery &&
              (requestStatus == null || request.status == requestStatus);
        }).toList();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Vue de supervision',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilotez les validations et suivez l’activité de QuickFix.',
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Stat(
                  label: 'Utilisateurs',
                  value: '${users.length}',
                  icon: Icons.people_outline,
                ),
                _Stat(
                  label: 'Artisans à valider',
                  value: '${pendingArtisans.length}',
                  icon: Icons.verified_user_outlined,
                ),
                _Stat(
                  label: 'Demandes en attente',
                  value: '$pendingRequests',
                  icon: Icons.assignment_late_outlined,
                ),
                _Stat(
                  label: 'Interventions en cours',
                  value: '$inProgress',
                  icon: Icons.handyman_outlined,
                ),
                _Stat(
                  label: 'Interventions terminées',
                  value: '$completed',
                  icon: Icons.task_alt_outlined,
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
              const Card(
                child: ListTile(title: Text('Aucun artisan en attente.')),
              )
            else
              ...pendingArtisans.map(
                (artisan) => _ArtisanReviewCard(artisan: artisan),
              ),
            const SizedBox(height: 28),
            Text(
              'Demandes récentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher une demande',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setLocalState(() => requestQuery = value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RequestStatus?>(
              initialValue: requestStatus,
              decoration: const InputDecoration(
                labelText: 'Filtrer par statut',
              ),
              items: [
                const DropdownMenuItem<RequestStatus?>(
                  value: null,
                  child: Text('Tous les statuts'),
                ),
                ...RequestStatus.values.map(
                  (status) => DropdownMenuItem<RequestStatus?>(
                    value: status,
                    child: Text(status.label),
                  ),
                ),
              ],
              onChanged: (value) => setLocalState(() => requestStatus = value),
            ),
            const SizedBox(height: 8),
            if (filteredRequests.isEmpty)
              const Card(
                child: ListTile(
                  title: Text('Aucune demande ne correspond au filtre.'),
                ),
              )
            else
              ...filteredRequests
                  .take(8)
                  .map(
                    (request) => Card(
                      child: ListTile(
                        title: Text(request.service),
                        subtitle: Text(
                          '${request.clientName} · ${request.artisanName}'
                          '${request.adminCorrection == null ? '' : '\nDernière correction : ${request.adminCorrection!.reason}'}',
                        ),
                        isThreeLine: request.adminCorrection != null,
                        trailing: DropdownButton<RequestStatus>(
                          value: request.status,
                          underline: const SizedBox.shrink(),
                          onChanged: (status) async {
                            if (status == null || status == request.status) {
                              return;
                            }
                            final correction =
                                await showDialog<_StatusCorrection>(
                                  context: context,
                                  builder: (_) => _StatusCorrectionDialog(
                                    previousStatus: request.status,
                                    nextStatus: status,
                                  ),
                                );
                            if (correction == null || !context.mounted) return;
                            try {
                              await controller.correctRequestStatus(
                                request: request,
                                status: status,
                                reason: correction.reason,
                              );
                            } on Exception {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Le statut n’a pas pu être corrigé.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          items: RequestStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 28),
            Text('Utilisateurs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: users
                    .take(20)
                    .map(
                      (user) => ListTile(
                        leading: CircleAvatar(
                          child: Text(user.name.characters.first),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        trailing: Chip(label: Text(user.role.label)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusCorrection {
  const _StatusCorrection(this.reason);

  final String reason;
}

class _StatusCorrectionDialog extends StatefulWidget {
  const _StatusCorrectionDialog({
    required this.previousStatus,
    required this.nextStatus,
  });

  final RequestStatus previousStatus;
  final RequestStatus nextStatus;

  @override
  State<_StatusCorrectionDialog> createState() =>
      _StatusCorrectionDialogState();
}

class _StatusCorrectionDialogState extends State<_StatusCorrectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Corriger le statut ?'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.previousStatus.label} → ${widget.nextStatus.label}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              minLines: 2,
              maxLines: 4,
              maxLength: 280,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Motif de la correction',
                helperText: 'Entre 10 et 280 caractères.',
              ),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                return length < 10
                    ? 'Décrivez le motif en au moins 10 caractères.'
                    : null;
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(context, _StatusCorrection(_reasonController.text));
        },
        child: const Text('Confirmer'),
      ),
    ],
  );
}

class _ArtisanReviewCard extends StatelessWidget {
  const _ArtisanReviewCard({required this.artisan});

  final Artisan artisan;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(artisan.name.characters.first)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    artisan.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.pending_actions_outlined),
                  label: Text(artisan.verificationStatus.label),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${artisan.trade.label} · ${artisan.area.label}\nTarif indicatif : dès ${artisan.startingPrice} DT',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _refuse(context, controller),
                    child: const Text('Refuser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _update(
                      context,
                      controller,
                      ArtisanVerificationStatus.verified,
                    ),
                    child: const Text('Valider'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refuse(BuildContext context, AppController controller) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser ce profil ?'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Motif facultatif'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !context.mounted) return;
    await _update(
      context,
      controller,
      ArtisanVerificationStatus.refused,
      reason: reason,
    );
  }

  Future<void> _update(
    BuildContext context,
    AppController controller,
    ArtisanVerificationStatus status, {
    String? reason,
  }) async {
    try {
      await controller.updateArtisanVerification(
        artisan.id,
        status,
        rejectionReason: reason,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == ArtisanVerificationStatus.verified
                  ? 'Profil validé.'
                  : 'Profil refusé.',
            ),
          ),
        );
      }
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La validation a échoué.')),
        );
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
    width: 190,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    ),
  );
}
