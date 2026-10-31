import 'package:flutter/material.dart';

import '../models/intervention_request.dart';

class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({super.key, required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      RequestStatus.pending => scheme.tertiary,
      RequestStatus.accepted || RequestStatus.inProgress => scheme.primary,
      RequestStatus.completed => scheme.secondary,
      RequestStatus.refused || RequestStatus.cancelled => scheme.error,
    };
    return Chip(
      avatar: Icon(Icons.circle, size: 10, color: color),
      label: Text(status.label),
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color.withValues(alpha: 0.45)),
    );
  }
}

class RequestTimeline extends StatelessWidget {
  const RequestTimeline({super.key, required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = <RequestStatus>[
      RequestStatus.pending,
      RequestStatus.accepted,
      RequestStatus.inProgress,
      RequestStatus.completed,
    ];
    final isTerminal =
        status == RequestStatus.refused || status == RequestStatus.cancelled;
    return Column(
      children: [
        if (isTerminal)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              status == RequestStatus.refused
                  ? Icons.block_outlined
                  : Icons.cancel_outlined,
            ),
            title: Text(status.label),
            subtitle: const Text('Cette demande est arrivée à son terme.'),
          )
        else
          for (var index = 0; index < steps.length; index++)
            _TimelineStep(
              label: steps[index].label,
              active: steps[index].index <= status.index,
              current: steps[index] == status,
              isLast: index == steps.length - 1,
            ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.active,
    required this.current,
    required this.isLast,
  });

  final String label;
  final bool active;
  final bool current;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.outlineVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Icon(
                current ? Icons.radio_button_checked : Icons.circle,
                size: current ? 18 : 12,
                color: color,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: color.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1, bottom: 12),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: current ? FontWeight.bold : null,
                color: active ? null : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.snapshot,
    required this.builder,
    this.empty,
  });

  final AsyncSnapshot<Object?> snapshot;
  final Widget Function() builder;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return const Center(child: Text('Impossible de charger ces données.'));
    }
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasData) return builder();
    return empty ?? const SizedBox.shrink();
  }
}
