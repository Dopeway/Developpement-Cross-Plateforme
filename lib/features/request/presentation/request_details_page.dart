import 'package:flutter/material.dart';

import '../../../core/models/intervention_request.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/responsive_page_layout.dart';
import '../../../core/widgets/request_status_widgets.dart';
import '../../../app/app_routes.dart';

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key, required this.request});

  final InterventionRequest request;

  @override
  Widget build(BuildContext context) {
    final user = AppScope.maybeOf(context)?.currentUser;
    final canChat =
        request.status.allowsChat &&
        (user?.id == request.clientId || user?.id == request.artisanId);
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la demande')),
      body: SafeArea(
        child: ResponsivePageLayout(
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
                  _PrivateAddressRow(request: request),
                  _DetailRow(
                    icon: Icons.schedule_outlined,
                    label: 'Créneau',
                    value: request.displayDate,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailSection(
                title: 'Description du besoin',
                children: [Text(request.description)],
              ),
              if (request.quoteAmount != null) ...[
                const SizedBox(height: 24),
                _DetailSection(
                  title: 'Devis associé à cette demande',
                  children: [
                    Text(
                      '${request.quoteAmount} DT',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ce devis fait partie du suivi de cette intervention.',
                    ),
                  ],
                ),
              ],
              if (request.status == RequestStatus.inProgress &&
                  user?.id == request.artisanId) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.interventionReport, arguments: request),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Renseigner le rapport'),
                ),
              ],
              if (request.status == RequestStatus.completed) ...[
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.interventionReport, arguments: request),
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('Consulter le rapport d’intervention'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRoutes.billingDocument, arguments: request),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    user?.id == request.artisanId
                        ? 'Préparer ou consulter le projet de facture'
                        : 'Consulter le projet de facture',
                  ),
                ),
              ],
              if (canChat) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamed(AppRoutes.chat, arguments: request),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Ouvrir la discussion'),
                ),
              ],
              const SizedBox(height: 24),
              _DetailSection(
                title: 'Suivi de la demande',
                children: [RequestTimeline(status: request.status)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivateAddressRow extends StatefulWidget {
  const _PrivateAddressRow({required this.request});

  final InterventionRequest request;

  @override
  State<_PrivateAddressRow> createState() => _PrivateAddressRowState();
}

class _PrivateAddressRowState extends State<_PrivateAddressRow> {
  Future<String>? _fullAddress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.maybeOf(context);
    final user = controller?.currentUser;
    final canRead =
        user?.id == widget.request.clientId ||
        (user?.id == widget.request.artisanId &&
            const [
              RequestStatus.accepted,
              RequestStatus.quoteAccepted,
              RequestStatus.inProgress,
              RequestStatus.completed,
            ].contains(widget.request.status));
    if (_fullAddress == null && controller != null && canRead) {
      _fullAddress = controller.getRequestFullAddress(widget.request);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _fullAddress,
    builder: (context, snapshot) => _DetailRow(
      icon: Icons.location_on_outlined,
      label: 'Adresse',
      value: snapshot.data ?? widget.request.address,
    ),
  );
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
