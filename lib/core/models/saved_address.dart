import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.value,
    required this.createdAt,
  });

  factory SavedAddress.fromJson(Map<String, Object?> json) {
    final createdAtValue = json['createdAt'];
    return SavedAddress(
      id: json['id']! as String,
      value: json['value']! as String,
      createdAt: switch (createdAtValue) {
        Timestamp timestamp => timestamp.toDate(),
        DateTime dateTime => dateTime,
        _ => null,
      },
    );
  }

  final String id;
  final String value;
  final DateTime? createdAt;
}
