import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/artisan.dart';
import '../../../core/models/intervention_request.dart';
import '../../../core/models/intervention_report.dart';

class RequestRepository {
  RequestRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _requests = (firestore ?? FirebaseFirestore.instance).collection(
        'requests',
      );

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _requests;

  Stream<List<InterventionRequest>> watchForUser(AppUser user) {
    final Query<Map<String, dynamic>> query = switch (user.role) {
      UserRole.client => _requests.where('clientId', isEqualTo: user.id),
      UserRole.artisan => _requests.where('artisanId', isEqualTo: user.id),
      UserRole.admin => _requests,
    };
    return query.snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map(
            (doc) => InterventionRequest.fromJson(<String, Object?>{
              'id': doc.id,
              ...doc.data(),
            }),
          )
          .toList();
      sortByNewest(requests);
      return requests;
    });
  }

  /// Keeps old requests visible until the dataset is migrated to `createdAt`.
  static void sortByNewest(List<InterventionRequest> requests) {
    requests.sort((left, right) {
      final leftDate = left.createdAt;
      final rightDate = right.createdAt;
      if (leftDate == null && rightDate == null) {
        return right.id.compareTo(left.id);
      }
      if (leftDate == null) return 1;
      if (rightDate == null) return -1;
      return rightDate.compareTo(leftDate);
    });
  }

  Future<void> create({
    required AppUser client,
    required Artisan artisan,
    required String description,
    required String address,
    required String slot,
  }) async {
    final document = _requests.doc();
    final batch = _firestore.batch();
    batch.set(document, {
      'service': artisan.trade.label,
      'artisanId': artisan.id,
      'artisanName': artisan.name,
      'clientId': client.id,
      'clientName': client.name,
      'description': description.trim(),
      'address': artisan.area.label,
      'date': slot,
      'status': RequestStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(document.collection('private').doc('location'), {
      'address': address.trim(),
    });
    await batch.commit();
  }

  Future<String> getFullAddress(InterventionRequest request) async {
    final location = await _requests
        .doc(request.id)
        .collection('private')
        .doc('location')
        .get();
    return location.data()?['address'] as String? ?? request.address;
  }

  Future<void> updateStatus({
    required String id,
    required RequestStatus status,
    int? quoteAmount,
  }) => _requests.doc(id).update({
    'status': status.name,
    'quoteAmount': ?quoteAmount,
  });

  Future<void> saveInterventionReport({
    required String id,
    required InterventionReport report,
  }) => _requests.doc(id).update({'interventionReport': report.toJson()});

  Future<void> completeIntervention({
    required String id,
    required InterventionReport report,
  }) {
    final reportData = report.toJson();
    reportData['completedAt'] = FieldValue.serverTimestamp();
    return _requests.doc(id).update({
      'status': RequestStatus.completed.name,
      'interventionReport': reportData,
    });
  }

  Future<void> correctStatus({
    required String id,
    required RequestStatus status,
    required RequestStatus previousStatus,
    required String reason,
    required String correctedBy,
  }) => _requests.doc(id).update(<String, Object?>{
    'status': status.name,
    'adminCorrection': <String, Object?>{
      'previousStatus': previousStatus.name,
      'reason': reason.trim(),
      'correctedBy': correctedBy,
      'correctedAt': FieldValue.serverTimestamp(),
    },
  });

  Future<InterventionRequest?> get(String id) async {
    final document = await _requests.doc(id).get();
    final data = document.data();
    if (data == null) return null;
    return InterventionRequest.fromJson(<String, Object?>{
      'id': document.id,
      ...data,
    });
  }

  Future<void> cancel(String id) =>
      updateStatus(id: id, status: RequestStatus.cancelled);
}
