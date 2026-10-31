import 'package:flutter/material.dart';

import '../../../core/models/artisan.dart';
import '../../../core/models/intervention_request.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/request_status_widgets.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return StreamBuilder<Artisan?>(
      stream: controller.artisanProfile,
      builder: (context, artisanSnapshot) {
        if (artisanSnapshot.hasError) {
          return const Center(
            child: Text('Impossible de charger votre profil.'),
          );
        }
        if (!artisanSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final artisan = artisanSnapshot.data;
        if (artisan == null) {
          return const Center(
            child: Text('Votre profil artisan est introuvable.'),
          );
        }
        return StreamBuilder<List<InterventionRequest>>(
          stream: controller.requests,
          builder: (context, requestSnapshot) {
            if (requestSnapshot.hasError) {
              return const Center(
                child: Text('Impossible de charger les interventions.'),
              );
            }
            if (!requestSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _Dashboard(
              artisan: artisan,
              requests: requestSnapshot.data!,
            );
          },
        );
      },
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.artisan, required this.requests});

  final Artisan artisan;
  final List<InterventionRequest> requests;

  @override
  Widget build(BuildContext context) {
    final pending = requests
        .where((r) => r.status == RequestStatus.pending)
        .toList();
    final accepted = requests
        .where((r) => r.status == RequestStatus.accepted)
        .toList();
    final inProgress = requests
        .where((r) => r.status == RequestStatus.inProgress)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Bonjour ${artisan.name}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        const Text('Traitez vos demandes et gardez votre activité à jour.'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Metric(
              label: 'Nouvelles demandes',
              value: '${pending.length}',
              icon: Icons.inbox_outlined,
            ),
            _Metric(
              label: 'Acceptées',
              value: '${accepted.length}',
              icon: Icons.check_circle_outline,
            ),
            _Metric(
              label: 'En cours',
              value: '${inProgress.length}',
              icon: Icons.handyman_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: Icon(
              artisan.verificationStatus == ArtisanVerificationStatus.verified
                  ? Icons.verified_outlined
                  : Icons.pending_actions_outlined,
            ),
            title: Text(artisan.verificationStatus.label),
            subtitle: Text(
              artisan.rejectionReason ??
                  (artisan.verificationStatus ==
                          ArtisanVerificationStatus.verified
                      ? 'Votre profil peut être présenté aux clients.'
                      : 'Votre profil est en cours d’examen par l’administration.'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _ActionSection(
          title: 'Nouvelles demandes',
          emptyMessage: 'Aucune nouvelle demande pour le moment.',
          requests: pending,
        ),
        const SizedBox(height: 24),
        _ActionSection(
          title: 'À démarrer',
          emptyMessage: 'Aucune intervention à démarrer.',
          requests: accepted,
        ),
        const SizedBox(height: 24),
        _ActionSection(
          title: 'Interventions en cours',
          emptyMessage: 'Aucune intervention en cours.',
          requests: inProgress,
        ),
        const SizedBox(height: 24),
        Text(
          'Votre profil professionnel',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.build_outlined),
                title: Text(artisan.trade),
                subtitle: const Text('Métier'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(artisan.area),
                subtitle: const Text('Zone d’intervention'),
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text('Dès ${artisan.startingPrice} DT'),
                subtitle: const Text('Tarif indicatif'),
              ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(
                  '${artisan.rating.toStringAsFixed(1)} (${artisan.reviewCount} avis)',
                ),
                subtitle: const Text('Évaluation'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Modifier le profil'),
                subtitle: const Text(
                  'Mettez à jour vos informations professionnelles.',
                ),
                onTap: () => _editProfile(context, artisan),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editProfile(BuildContext context, Artisan artisan) async {
    final input = await showDialog<_ProfileInput>(
      context: context,
      builder: (_) => _ProfileDialog(artisan: artisan),
    );
    if (input == null || !context.mounted) return;
    try {
      await AppScope.of(context).updateArtisanProfile(
        name: input.name,
        trade: input.trade,
        area: input.area,
        startingPrice: input.startingPrice,
        availableToday: input.availableToday,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil mis à jour.')));
      }
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le profil n’a pas pu être mis à jour.'),
          ),
        );
      }
    }
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.title,
    required this.emptyMessage,
    required this.requests,
  });

  final String title;
  final String emptyMessage;
  final List<InterventionRequest> requests;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (requests.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(emptyMessage),
          ),
        )
      else
        ...requests.map((request) => _RequestActionCard(request: request)),
    ],
  );
}

class _ProfileInput {
  const _ProfileInput({
    required this.name,
    required this.trade,
    required this.area,
    required this.startingPrice,
    required this.availableToday,
  });

  final String name;
  final String trade;
  final String area;
  final int startingPrice;
  final bool availableToday;
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.artisan});

  final Artisan artisan;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.artisan.name,
  );
  late final TextEditingController _trade = TextEditingController(
    text: widget.artisan.trade,
  );
  late final TextEditingController _area = TextEditingController(
    text: widget.artisan.area,
  );
  late final TextEditingController _price = TextEditingController(
    text: '${widget.artisan.startingPrice}',
  );
  late bool _available = widget.artisan.availableToday;

  @override
  void dispose() {
    _name.dispose();
    _trade.dispose();
    _area.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Modifier le profil'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nom affiché'),
          ),
          TextField(
            controller: _trade,
            decoration: const InputDecoration(labelText: 'Métier'),
          ),
          TextField(
            controller: _area,
            decoration: const InputDecoration(labelText: 'Zone d’intervention'),
          ),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Tarif de départ (DT)',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Disponible aujourd’hui'),
            value: _available,
            onChanged: (value) => setState(() => _available = value),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () {
          final price = int.tryParse(_price.text);
          if (_name.text.trim().length < 2 ||
              _trade.text.trim().length < 2 ||
              _area.text.trim().length < 2 ||
              price == null ||
              price < 0) {
            return;
          }
          Navigator.pop(
            context,
            _ProfileInput(
              name: _name.text,
              trade: _trade.text,
              area: _area.text,
              startingPrice: price,
              availableToday: _available,
            ),
          );
        },
        child: const Text('Enregistrer'),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

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

class _RequestActionCard extends StatefulWidget {
  const _RequestActionCard({required this.request});

  final InterventionRequest request;

  @override
  State<_RequestActionCard> createState() => _RequestActionCardState();
}

class _RequestActionCardState extends State<_RequestActionCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final nextStatus = request.status.nextArtisanStatus;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.service,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                RequestStatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('${request.clientName}\n${request.address}\n${request.date}'),
            const SizedBox(height: 8),
            Text(request.description),
            const SizedBox(height: 16),
            Row(
              children: [
                if (request.status == RequestStatus.pending)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _handleAction(RequestStatus.refused),
                      child: const Text('Refuser'),
                    ),
                  ),
                if (request.status == RequestStatus.pending)
                  const SizedBox(width: 12),
                if (nextStatus != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : () => _handleAction(nextStatus),
                      child: _busy
                          ? const CircularProgressIndicator()
                          : Text(_actionLabel(nextStatus)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _actionLabel(RequestStatus status) => switch (status) {
    RequestStatus.accepted => 'Accepter',
    RequestStatus.inProgress => 'Démarrer l’intervention',
    RequestStatus.completed => 'Terminer l’intervention',
    _ => 'Mettre à jour',
  };

  String _successMessage(RequestStatus status) => switch (status) {
    RequestStatus.accepted => 'Demande acceptée.',
    RequestStatus.inProgress => 'Intervention démarrée.',
    RequestStatus.completed => 'Intervention terminée.',
    _ => 'Demande mise à jour.',
  };

  Future<void> _handleAction(RequestStatus status) async {
    if (status != RequestStatus.completed && status != RequestStatus.refused) {
      await _update(status, _successMessage(status));
      return;
    }
    final isRefusal = status == RequestStatus.refused;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isRefusal ? 'Refuser la demande ?' : 'Terminer l’intervention ?',
        ),
        content: Text(
          isRefusal
              ? 'Cette demande ne pourra plus être acceptée après confirmation.'
              : 'Confirmez uniquement lorsque l’intervention est réellement terminée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isRefusal ? 'Conserver' : 'Pas encore'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isRefusal ? 'Refuser la demande' : 'Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _update(status, _successMessage(status));
    }
  }

  Future<void> _update(RequestStatus status, String message) async {
    setState(() => _busy = true);
    try {
      await AppScope.of(context).updateRequestStatus(widget.request.id, status);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La mise à jour a échoué.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
