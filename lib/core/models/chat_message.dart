class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, Object?> json) => ChatMessage(
    id: json['id']! as String,
    senderId: json['senderId']! as String,
    senderName: json['senderName']! as String,
    content: json['content']! as String,
    createdAt: json['createdAt'] as DateTime?,
  );

  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime? createdAt;
}
