import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/artisan.dart';

class ProfileRegistrationRepository {
  ProfileRegistrationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> completeRegistration({
    required AppUser user,
    required Artisan? artisan,
    required bool createUser,
    required bool createArtisan,
  }) async {
    if (!createUser && !createArtisan) return;

    final userDocument = _firestore.collection('users').doc(user.id);
    final artisanDocument = _firestore.collection('artisans').doc(user.id);
    await _firestore.runTransaction((transaction) async {
      if (createUser) transaction.set(userDocument, user.toJson());
      if (createArtisan) transaction.set(artisanDocument, artisan!.toJson());
    });
  }
}
