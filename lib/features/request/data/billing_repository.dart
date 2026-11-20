import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/billing_document.dart';

class BillingRepository {
  BillingRepository({FirebaseFirestore? firestore})
    : _requests = (firestore ?? FirebaseFirestore.instance).collection(
        'requests',
      );

  final CollectionReference<Map<String, dynamic>> _requests;

  DocumentReference<Map<String, dynamic>> _document(String requestId) =>
      _requests.doc(requestId).collection('billing').doc('document');

  Future<BillingDocument?> get(String requestId) async {
    final snapshot = await _document(requestId).get();
    final data = snapshot.data();
    return data == null ? null : BillingDocument.fromJson(data);
  }

  Future<void> create(BillingDocument document) => _document(document.requestId)
      .set({...document.toJson(), 'createdAt': FieldValue.serverTimestamp()});
}
