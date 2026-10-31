import 'package:flutter/material.dart';

import '../../../core/models/intervention_request.dart';
import '../../../core/widgets/request_status_widgets.dart';

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key, required this.request});

  final InterventionRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la demande')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              request.service,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            RequestStatusChip(status: request.status),
            const SizedBox(height: 24),
            _DetailSection(
              title: 'Intervention',
              children: [
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Artisan',
                  value: request.artisanName,
                ),
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Client',
                  value: request.clientName,
                ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Adresse',
                  value: request.address,
                ),
                _DetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Créneau',
                  value: request.date,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailSection(
              title: 'Description du besoin',
              children: [Text(request.description)],
            ),
            const SizedBox(height: 24),
            _DetailSection(
              title: 'Suivi de la demande',
              children: [RequestTimeline(status: request.status)],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    ),
  );
}
