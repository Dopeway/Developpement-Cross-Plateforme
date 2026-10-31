import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/artisan.dart';
import '../../../core/models/intervention_request.dart';
import '../../../core/state/app_scope.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final role = controller.currentUser!.role;
    return StreamBuilder<List<InterventionRequest>>(
      stream: controller.requests,
      builder: (context, requestSnapshot) {
        if (requestSnapshot.hasError) {
          return const _NotificationState(
            icon: Icons.cloud_off_outlined,
            message: 'Les notifications sont momentanément indisponibles.',
          );
        }
        if (!requestSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (role != UserRole.admin) {
          return _NotificationList(
            notifications: _fromRequests(requestSnapshot.data!, role),
          );
        }
        return StreamBuilder<List<Artisan>>(
          stream: controller.pendingArtisans,
          builder: (context, artisanSnapshot) {
            if (!artisanSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _NotificationList(
              notifications: [
                ..._fromRequests(requestSnapshot.data!, role),
                ...artisanSnapshot.data!.map(
                  (artisan) => _NotificationItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Profil artisan à examiner',
                    message: '${artisan.name} attend votre validation.',
                    date: '${artisan.trade} · ${artisan.area}',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<_NotificationItem> _fromRequests(
    List<InterventionRequest> requests,
    UserRole role,
  ) => requests
      .where((request) => request.status != RequestStatus.completed)
      .map(
        (request) => _NotificationItem(
          icon: _iconFor(request.status),
          title: role == UserRole.client
              ? 'Demande ${request.status.label.toLowerCase()}'
              : 'Intervention ${request.status.label.toLowerCase()}',
          message: role == UserRole.client
              ? '${request.service} avec ${request.artisanName}'
              : '${request.service} pour ${request.clientName}',
          date: request.date,
        ),
      )
      .toList();

  static IconData _iconFor(RequestStatus status) => switch (status) {
    RequestStatus.pending => Icons.schedule_outlined,
    RequestStatus.accepted => Icons.check_circle_outline,
    RequestStatus.inProgress => Icons.handyman_outlined,
    RequestStatus.refused => Icons.block_outlined,
    RequestStatus.cancelled => Icons.cancel_outlined,
    RequestStatus.completed => Icons.task_alt_outlined,
  };
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.notifications});

  final List<_NotificationItem> notifications;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const _NotificationState(
        icon: Icons.notifications_none_outlined,
        message: 'Aucune nouvelle notification.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: notifications.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(notification.icon)),
            title: Text(notification.title),
            subtitle: Text('${notification.message}\n${notification.date}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class _NotificationState extends StatelessWidget {
  const _NotificationState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _NotificationItem {
  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.date,
  });

  final IconData icon;
  final String title;
  final String message;
  final String date;
}
