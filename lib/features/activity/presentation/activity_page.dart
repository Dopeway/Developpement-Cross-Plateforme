import 'package:flutter/material.dart';

import '../../../core/models/artisan.dart';
import '../../../core/models/artisan_catalog.dart';
import '../../../core/models/intervention_request.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/request_status_widgets.dart';
import 'missing_artisan_profile.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return StreamBuilder<Artisan?>(
      stream: controller.artisanProfile,
      builder: (context, artisanSnapshot) {
        if (artisanSnapshot.hasError) {
          return ErrorStateView(
            message: 'Impossible de charger votre profil.',
            onRetry: () => setState(() {}),
          );
        }
        if (artisanSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final artisan = artisanSnapshot.data;
        if (artisan == null) {
          return const MissingArtisanProfile();
        }
        return StreamBuilder<List<InterventionRequest>>(
          stream: controller.requests,
          builder: (context, requestSnapshot) {
            if (requestSnapshot.hasError) {
              return ErrorStateView(
                message: 'Impossible de charger les interventions.',
                onRetry: () => setState(() {}),
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
              label: 'Confirmées',
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
          title: 'Demandes à chiffrer',
          emptyMessage: 'Aucune demande à chiffrer pour le moment.',
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
                title: Text(artisan.trade.label),
                subtitle: const Text('Métier'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(artisan.area.label),
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
  });

  final String name;
  final ArtisanTrade trade;
  final InterventionArea area;
  final int startingPrice;
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.artisan});

  final Artisan artisan;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.artisan.name,
  );
  late ArtisanTrade _trade = widget.artisan.trade;
  late InterventionArea _area = widget.artisan.area;
  late final TextEditingController _price = TextEditingController(
    text: '${widget.artisan.startingPrice}',
  );

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Modifier le profil'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nom affiché'),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Indiquez un nom d’au moins 2 caractères.'
                  : null,
            ),
            DropdownButtonFormField<ArtisanTrade>(
              initialValue: _trade,
              decoration: const InputDecoration(labelText: 'Métier'),
              items: ArtisanTrade.values
                  .map(
                    (trade) => DropdownMenuItem(
                      value: trade,
                      child: Text(trade.label),
                    ),
                  )
                  .toList(),
              onChanged: (trade) {
                if (trade != null) setState(() => _trade = trade);
              },
            ),
            DropdownButtonFormField<InterventionArea>(
              initialValue: _area,
              decoration: const InputDecoration(
                labelText: 'Zone d’intervention',
              ),
              items: InterventionArea.values
                  .map(
                    (area) =>
                        DropdownMenuItem(value: area, child: Text(area.label)),
                  )
                  .toList(),
              onChanged: (area) {
                if (area != null) setState(() => _area = area);
              },
            ),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tarif de départ (DT)',
              ),
              validator: (value) {
                final price = int.tryParse(value ?? '');
                return price == null || price < 0
                    ? 'Indiquez un tarif valide.'
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
          final price = int.parse(_price.text);
          Navigator.pop(
            context,
            _ProfileInput(
              name: _name.text,
              trade: _trade,
              area: _area,
              startingPrice: price,
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
    RequestStatus.awaitingQuote => 'Envoyer le devis',
    RequestStatus.inProgress => 'Démarrer l’intervention',
    RequestStatus.completed => 'Terminer l’intervention',
    _ => 'Mettre à jour',
  };

  String _successMessage(RequestStatus status) => switch (status) {
    RequestStatus.awaitingQuote => 'Devis envoyé au client.',
    RequestStatus.inProgress => 'Intervention démarrée.',
    RequestStatus.completed => 'Intervention terminée.',
    _ => 'Demande mise à jour.',
  };

  Future<void> _handleAction(RequestStatus status) async {
    if (status == RequestStatus.awaitingQuote) {
      final amount = await _askQuoteAmount();
      if (amount != null && mounted) {
        await _update(status, _successMessage(status), quoteAmount: amount);
      }
      return;
    }
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

  Future<int?> _askQuoteAmount() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Envoyer un devis'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Montant estimé (DT)',
            helperText: 'Le client devra accepter ce devis.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount >= 0) {
                Navigator.pop(dialogContext, amount);
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _update(
    RequestStatus status,
    String message, {
    int? quoteAmount,
  }) async {
    setState(() => _busy = true);
    try {
      await AppScope.of(context).updateRequestStatus(
        widget.request.id,
        status,
        quoteAmount: quoteAmount,
      );
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
