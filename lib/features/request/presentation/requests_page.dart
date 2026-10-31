import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/intervention_request.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/request_status_widgets.dart';
import '../../../app/app_routes.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  RequestStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InterventionRequest>>(
      stream: AppScope.of(context).requests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Impossible de charger les demandes.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!
            .where((request) => _filter == null || request.status == _filter)
            .toList();
        return _buildContent(context, requests);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<InterventionRequest> requests,
  ) {
    final role = AppScope.of(context).currentUser!.role;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          role == UserRole.artisan
              ? 'Retrouvez toutes vos interventions.'
              : role == UserRole.admin
              ? 'Consultez l’activité de la plateforme.'
              : 'Suivez vos interventions et retrouvez leur historique.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Toutes'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            ...RequestStatus.values.map(
              (status) => FilterChip(
                label: Text(status.label),
                selected: _filter == status,
                onSelected: (selected) =>
                    setState(() => _filter = selected ? status : null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Aucune demande dans cette catégorie.'),
              ),
            ),
          )
        else
          ...requests.map((request) => _requestCard(context, request, role)),
      ],
    );
  }

  Widget _requestCard(
    BuildContext context,
    InterventionRequest request,
    UserRole role,
  ) => Card(
    key: ValueKey('request-${request.id}'),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          Navigator.of(context)
              .pushNamed(AppRoutes.requestDetails, arguments: request),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              role == UserRole.artisan
                  ? '${request.clientName}\n${request.address}\n${request.date}'
                  : '${request.artisanName}\n${request.address}\n${request.date}',
            ),
            const SizedBox(height: 12),
            Text(request.description),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Voir le détail'),
                SizedBox(width: 4),
                Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 16),
            RequestTimeline(status: request.status),
            if (role == UserRole.client &&
                request.status == RequestStatus.pending)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _cancel(context, request),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler la demande'),
                ),
              ),
            if (role == UserRole.client &&
                request.status == RequestStatus.completed)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _review(context, request),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Donner un avis'),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _cancel(
    BuildContext context,
    InterventionRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la demande ?'),
        content: const Text('Cette action ne pourra pas être annulée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conserver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Annuler la demande'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await AppScope.of(context)
          .updateRequestStatus(request.id, RequestStatus.cancelled);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Demande annulée.')));
      }
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L’annulation n’a pas abouti.')),
        );
      }
    }
  }

  Future<void> _review(
    BuildContext context,
    InterventionRequest request,
  ) async {
    final input = await showDialog<_ReviewInput>(
      context: context,
      builder: (_) => const _ReviewDialog(),
    );
    if (input == null || !context.mounted) return;
    try {
      await AppScope.of(context).createReview(
        request: request,
        rating: input.rating,
        comment: input.comment,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Merci pour votre avis.')));
      }
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cet avis n’a pas pu être enregistré.')),
        );
      }
    }
  }
}

class _ReviewInput {
  const _ReviewInput(this.rating, this.comment);

  final int rating;
  final String comment;
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _controller = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Votre avis'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1')),
            ButtonSegment(value: 2, label: Text('2')),
            ButtonSegment(value: 3, label: Text('3')),
            ButtonSegment(value: 4, label: Text('4')),
            ButtonSegment(value: 5, label: Text('5')),
          ],
          selected: {_rating},
          onSelectionChanged: (value) => setState(() => _rating = value.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Votre commentaire',
            hintText: 'Partagez votre expérience.',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Plus tard'),
      ),
      FilledButton(
        onPressed: () {
          if (_controller.text.trim().isEmpty) return;
          Navigator.pop(context, _ReviewInput(_rating, _controller.text));
        },
        child: const Text('Publier'),
      ),
    ],
  );
}
