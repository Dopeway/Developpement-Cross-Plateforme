import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  requestCreated,
  requestAccepted,
  interventionStarted,
  interventionCompleted,
  requestRefused,
  requestCancelled,
  reviewCreated,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.requestId,
  });

  factory AppNotification.fromJson(Map<String, Object?> json) {
    final createdAtValue = json['createdAt'];
    final createdAt = switch (createdAtValue) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime dateTime => dateTime,
      _ => null,
    };
    return AppNotification(
      id: json['id']! as String,
      recipientId: json['recipientId']! as String,
      type: AppNotificationType.values.byName(json['type']! as String),
      title: json['title']! as String,
      message: json['message']! as String,
      isRead: json['isRead']! as bool,
      createdAt: createdAt,
      requestId: json['requestId'] as String?,
    );
  }

  final String id;
  final String recipientId;
  final AppNotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final String? requestId;
}
