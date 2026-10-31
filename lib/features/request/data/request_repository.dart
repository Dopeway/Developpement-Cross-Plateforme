import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/artisan.dart';
import '../../../core/models/intervention_request.dart';

class RequestRepository {
  RequestRepository({FirebaseFirestore? firestore})
    : _requests = (firestore ?? FirebaseFirestore.instance).collection(
        'requests',
      );

  final CollectionReference<Map<String, dynamic>> _requests;

  Stream<List<InterventionRequest>> watchForUser(AppUser user) {
    final Query<Map<String, dynamic>> query = switch (user.role) {
      UserRole.client => _requests.where('clientId', isEqualTo: user.id),
      UserRole.artisan => _requests.where('artisanId', isEqualTo: user.id),
      UserRole.admin => _requests,
    };
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (doc) => InterventionRequest.fromJson(<String, Object?>{
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList()
            ..sort((a, b) => b.id.compareTo(a.id)),
    );
  }

  Future<void> create({
    required AppUser client,
    required Artisan artisan,
    required String description,
    required String address,
    required String slot,
  }) => _requests.add({
    'service': artisan.trade,
    'artisanId': artisan.id,
    'artisanName': artisan.name,
    'clientId': client.id,
    'clientName': client.name,
    'description': description.trim(),
    'address': address.trim(),
    'date': slot,
    'status': RequestStatus.pending.name,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateStatus({
    required String id,
    required RequestStatus status,
  }) => _requests.doc(id).update({'status': status.name});

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
