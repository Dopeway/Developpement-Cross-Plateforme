import 'package:flutter/material.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/state/app_scope.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _markingAllAsRead = false;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return StreamBuilder<List<AppNotification>>(
      stream: controller.notifications,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _NotificationState(
            icon: Icons.cloud_off_outlined,
            message: 'Les notifications sont momentanément indisponibles.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snapshot.data!;
        final hasUnread = notifications.any(
          (notification) => !notification.isRead,
        );
        if (notifications.isEmpty) {
          return const _NotificationState(
            icon: Icons.notifications_none_outlined,
            message: 'Vous n’avez aucune notification pour le moment.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: notifications.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vos notifications',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (hasUnread)
                    TextButton.icon(
                      onPressed: _markingAllAsRead ? null : _markAllAsRead,
                      icon: _markingAllAsRead
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.done_all_outlined),
                      label: const Text('Tout lire'),
                    ),
                ],
              );
            }
            final notification = notifications[index - 1];
            return _NotificationCard(
              notification: notification,
              onTap: () => _markAsRead(notification),
            );
          },
        );
      },
    );
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await AppScope.of(context).markNotificationAsRead(notification.id);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La notification n’a pas pu être mise à jour.'),
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _markingAllAsRead = true);
    try {
      await AppScope.of(context).markAllNotificationsAsRead();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les notifications n’ont pas pu être mises à jour.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAllAsRead = false);
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('notification-${notification.id}'),
      color: notification.isRead ? null : colorScheme.secondaryContainer,
      child: ListTile(
        onTap: onTap,
        leading: Icon(_iconFor(notification.type)),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${notification.message}\n${_formatDate(notification.createdAt)}',
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _iconFor(AppNotificationType type) => switch (type) {
    AppNotificationType.requestCreated => Icons.assignment_outlined,
    AppNotificationType.requestAccepted => Icons.check_circle_outline,
    AppNotificationType.interventionStarted => Icons.handyman_outlined,
    AppNotificationType.interventionCompleted => Icons.rate_review_outlined,
    AppNotificationType.requestRefused => Icons.block_outlined,
    AppNotificationType.requestCancelled => Icons.cancel_outlined,
    AppNotificationType.reviewCreated => Icons.star_outline,
  };

  String _formatDate(DateTime? date) {
    if (date == null) return 'À l’instant';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'À l’instant';
    if (difference.inHours < 1) return 'Il y a ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Il y a ${difference.inHours} h';
    return 'Il y a ${difference.inDays} j';
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
