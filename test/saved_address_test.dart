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
}
