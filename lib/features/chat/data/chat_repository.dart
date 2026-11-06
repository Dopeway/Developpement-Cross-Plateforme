import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/chat_message.dart';

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _messages(String requestId) =>
      _firestore.collection('requests').doc(requestId).collection('messages');

  Stream<List<ChatMessage>> watchMessages(String requestId) =>
      _messages(requestId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map((document) {
              final data = document.data();
              final createdAt = data['createdAt'];
              return ChatMessage.fromJson(<String, Object?>{
                'id': document.id,
                ...data,
                'createdAt': createdAt is Timestamp ? createdAt.toDate() : null,
              });
            }).toList(),
          );

  Future<void> send({
    required String requestId,
    required String senderId,
    required String senderName,
    required String content,
  }) => _messages(requestId).add(<String, Object?>{
    'senderId': senderId,
    'senderName': senderName,
    'content': content.trim(),
    'createdAt': FieldValue.serverTimestamp(),
  });
}
