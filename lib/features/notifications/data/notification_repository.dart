import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/app_notification.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _notifications = (firestore ?? FirebaseFirestore.instance).collection(
        'notifications',
      );

  final CollectionReference<Map<String, dynamic>> _notifications;

  Stream<List<AppNotification>> watchForUser(String userId) => _notifications
      .where('recipientId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (document) => AppNotification.fromJson(<String, Object?>{
                'id': document.id,
                ...document.data(),
              }),
            )
            .toList(),
      );

  Stream<int> watchUnreadCount(String userId) => _notifications
      .where('recipientId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.size);

  Future<void> markAsRead(String notificationId) => _notifications
      .doc(notificationId)
      .update(<String, Object?>{'isRead': true});

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _notifications
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    var batch = _notifications.firestore.batch();
    var count = 0;
    for (final document in snapshot.docs) {
      batch.update(document.reference, <String, Object?>{'isRead': true});
      count++;
      if (count == 500) {
        await batch.commit();
        batch = _notifications.firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }
}
