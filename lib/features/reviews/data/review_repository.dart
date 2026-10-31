import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/intervention_request.dart';
import '../../../core/models/review.dart';

class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore})
    : _reviews = (firestore ?? FirebaseFirestore.instance).collection(
        'reviews',
      );

  final CollectionReference<Map<String, dynamic>> _reviews;

  Stream<List<Review>> watchForArtisan(String artisanId) => _reviews
      .where('artisanId', isEqualTo: artisanId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => Review.fromJson(<String, Object?>{
                'id': doc.id,
                ...doc.data(),
              }),
            )
            .toList(),
      );

  Future<bool> existsForRequest(String requestId) async =>
      (await _reviews.doc(requestId).get()).exists;

  Future<void> create({
    required InterventionRequest request,
    required int rating,
    required String comment,
  }) => _reviews.doc(request.id).set({
    'requestId': request.id,
    'clientId': request.clientId,
    'artisanId': request.artisanId,
    'rating': rating,
    'comment': comment.trim(),
    'createdAt': FieldValue.serverTimestamp(),
  });
}
