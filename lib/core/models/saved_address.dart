import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.isDefault,
    required this.createdAt,
  });

  factory SavedAddress.fromJson(Map<String, Object?> json) {
    final createdAtValue = json['createdAt'];
    return SavedAddress(
      id: json['id']! as String,
      label: json['label'] as String? ?? 'Adresse',
      fullAddress: (json['fullAddress'] ?? json['value'])! as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: switch (createdAtValue) {
        Timestamp timestamp => timestamp.toDate(),
        DateTime dateTime => dateTime,
        _ => null,
      },
    );
  }

  final String id;
  final String label;
  final String fullAddress;
  final bool isDefault;
  final DateTime? createdAt;

  /// CompatibilitÃ© des adresses enregistrÃ©es avant le parcours de rÃ©servation.
  String get value => fullAddress;
}

String? pickSavedAddressId(
  Iterable<SavedAddress> addresses,
  String? selectedId,
) {
  for (final address in addresses) {
    if (address.id == selectedId) return address.id;
  }
  for (final address in addresses) {
    if (address.isDefault) return address.id;
  }
  return addresses.isEmpty ? null : addresses.first.id;
}
