import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/app_user.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _users = (firestore ?? FirebaseFirestore.instance).collection('users');

  final CollectionReference<Map<String, dynamic>> _users;

  Stream<AppUser?> watchUser(String id) =>
      _users.doc(id).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) return null;
        return AppUser.fromJson(<String, Object?>{'id': doc.id, ...data});
      });

  Future<AppUser?> getUser(String id) async {
    final document = await _users.doc(id).get();
    final data = document.data();
    if (data == null) return null;
    return AppUser.fromJson(<String, Object?>{'id': document.id, ...data});
  }

  Future<void> createUser({
    required String id,
    required String name,
    required String email,
    required UserRole role,
  }) => _users
      .doc(id)
      .set(
        AppUser(
          id: id,
          name: name.trim(),
          email: email.trim(),
          role: role,
        ).toJson(),
      );

  Future<void> updateProfile(AppUser user) =>
      _users.doc(user.id).update({'name': user.name});
}
