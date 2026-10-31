class Review {
  const Review({
    required this.id,
    required this.requestId,
    required this.clientId,
    required this.artisanId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, Object?> json) => Review(
    id: json['id']! as String,
    requestId: json['requestId']! as String,
    clientId: json['clientId']! as String,
    artisanId: json['artisanId']! as String,
    rating: json['rating']! as int,
    comment: json['comment']! as String,
    createdAt: json['createdAt']?.toString(),
  );

  final String id;
  final String requestId;
  final String clientId;
  final String artisanId;
  final int rating;
  final String comment;
  final String? createdAt;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'clientId': clientId,
    'artisanId': artisanId,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt,
  };
}
