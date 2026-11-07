import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/saved_address.dart';

void main() {
  test('désérialise une adresse enregistrée', () {
    final address = SavedAddress.fromJson(<String, Object?>{
      'id': 'address-1',
      'value': '12 rue des Jasmins, Tunis',
      'createdAt': Timestamp.fromDate(DateTime(2026, 11, 6)),
    });

    expect(address.id, 'address-1');
    expect(address.value, '12 rue des Jasmins, Tunis');
    expect(address.createdAt, DateTime(2026, 11, 6));
  });

  test('conserve une sélection par identifiant après un rafraîchissement', () {
    const firstSnapshot = [
      SavedAddress(
        id: 'address-1',
        label: 'Domicile',
        fullAddress: '12 rue des Jasmins, Tunis',
        isDefault: true,
        createdAt: null,
      ),
    ];
    const refreshedSnapshot = [
      SavedAddress(
        id: 'address-1',
        label: 'Domicile',
        fullAddress: '12 rue des Jasmins, Tunis',
        isDefault: true,
        createdAt: null,
      ),
    ];

    expect(pickSavedAddressId(firstSnapshot, 'address-1'), 'address-1');
    expect(pickSavedAddressId(refreshedSnapshot, 'address-1'), 'address-1');
  });
}
