import 'package:flutter/material.dart';

import '../../../core/models/intervention_request.dart';
import '../../../core/state/demo_scope.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});
  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  RequestStatus? _filter;

  Color _color(RequestStatus status) => switch (status) {
    RequestStatus.accepted => const Color(0xFF0B6B58),
    RequestStatus.completed => const Color(0xFF4C6070),
    RequestStatus.pending => const Color(0xFF9A6700),
    _ => const Color(0xFFB3261E),
  };

  @override
  Widget build(BuildContext context) {
    final requests = DemoScope.of(context)
        .requestsForCurrentUser()
        .where((request) => _filter == null || request.status == _filter)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Suivez vos interventions et retrouvez leur historique.'),
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
        const SizedBox(height: 12),
        if (requests.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('Aucune demande dans cette catégorie.')),
          ),
        ...requests.map(
          (request) => Card(
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
                      Chip(
                        label: Text(request.status.label),
                        side: BorderSide(color: _color(request.status)),
                        labelStyle: TextStyle(color: _color(request.status)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${request.artisanName}\n${request.date}\nRéférence ${request.id}',
                  ),
                  if (request.status == RequestStatus.completed)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Merci, votre avis est enregistré en démonstration.',
                                ),
                              ),
                            ),
                        icon: const Icon(Icons.star_outline),
                        label: const Text('Donner un avis'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
