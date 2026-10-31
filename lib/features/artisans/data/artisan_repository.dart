import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/artisan.dart';

class ArtisanRepository {
  ArtisanRepository({FirebaseFirestore? firestore})
    : _artisans = (firestore ?? FirebaseFirestore.instance).collection(
        'artisans',
      );

  final CollectionReference<Map<String, dynamic>> _artisans;

  Stream<List<Artisan>> watchArtisans() => _artisans
      .where('verified', isEqualTo: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => Artisan.fromJson(<String, Object?>{
                'id': doc.id,
                ...doc.data(),
              }),
            )
            .toList(),
      );

  Stream<Artisan?> watchArtisan(String id) =>
      _artisans.doc(id).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (data == null) return null;
        return Artisan.fromJson(<String, Object?>{'id': snapshot.id, ...data});
      });

  Stream<List<Artisan>> watchPendingArtisans() => _artisans
      .where('verified', isEqualTo: false)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => Artisan.fromJson(<String, Object?>{
                'id': doc.id,
                ...doc.data(),
              }),
            )
            .toList(),
      );

  Future<Artisan?> getArtisan(String id) async {
    final document = await _artisans.doc(id).get();
    final data = document.data();
    if (data == null) return null;
    return Artisan.fromJson(<String, Object?>{'id': document.id, ...data});
  }

  Future<void> createArtisanProfile({
    required String id,
    required String name,
    required String trade,
    required String area,
    required int startingPrice,
  }) => _artisans
      .doc(id)
      .set(
        Artisan(
          id: id,
          name: name.trim(),
          trade: trade.trim(),
          area: area.trim(),
          rating: 0,
          reviewCount: 0,
          startingPrice: startingPrice,
          verified: false,
          availableToday: true,
          verificationStatus: ArtisanVerificationStatus.pending,
        ).toJson(),
      );

  Future<void> updateVerification({
    required String id,
    required ArtisanVerificationStatus status,
    String? rejectionReason,
  }) => _artisans.doc(id).update({
    'verified': status == ArtisanVerificationStatus.verified,
    'verificationStatus': status.name,
    'rejectionReason': rejectionReason,
  });

  Future<void> updateProfile({
    required String id,
    required String name,
    required String trade,
    required String area,
    required int startingPrice,
    required bool availableToday,
  }) => _artisans.doc(id).update({
    'name': name.trim(),
    'trade': trade.trim(),
    'area': area.trim(),
    'startingPrice': startingPrice,
    'availableToday': availableToday,
  });
}
