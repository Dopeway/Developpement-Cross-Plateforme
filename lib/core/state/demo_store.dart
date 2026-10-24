import 'package:flutter/foundation.dart';

import '../data/demo_repository.dart';
import '../models/app_user.dart';
import '../models/artisan.dart';
import '../models/intervention_request.dart';

class DemoStore extends ChangeNotifier {
  DemoStore(DemoSeed seed)
    : _users = seed.users,
      _artisans = seed.artisans,
      _requests = seed.requests;

  final List<AppUser> _users;
  final List<Artisan> _artisans;
  final List<InterventionRequest> _requests;
  AppUser? _currentUser;
  int _nextRequestNumber = 1049;

  AppUser? get currentUser => _currentUser;
  List<Artisan> get artisans => List.unmodifiable(_artisans);
  List<InterventionRequest> get requests => List.unmodifiable(_requests);

  bool login({required String email, required String password}) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final user in _users) {
      if (user.email == normalizedEmail && user.password == password) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  List<InterventionRequest> requestsForCurrentUser() {
    final user = _currentUser;
    if (user == null) return const [];
    return switch (user.role) {
      UserRole.client =>
        _requests.where((request) => request.clientId == user.id).toList(),
      UserRole.artisan =>
        _requests.where((request) => request.artisanId == user.id).toList(),
      UserRole.admin => List.of(_requests),
    };
  }

  void createRequest({
    required Artisan artisan,
    required String description,
    required String address,
    required String slot,
  }) {
    final user = _currentUser;
    if (user == null || user.role != UserRole.client) return;
    _requests.insert(
      0,
      InterventionRequest(
        id: 'QF-${_nextRequestNumber++}',
        service: artisan.trade,
        artisanId: artisan.id,
        artisanName: artisan.name,
        clientId: user.id,
        clientName: user.name,
        description: description.trim(),
        address: address.trim(),
        date: slot,
        status: RequestStatus.pending,
      ),
    );
    notifyListeners();
  }

  void updateRequestStatus(String id, RequestStatus status) {
    final index = _requests.indexWhere((request) => request.id == id);
    if (index == -1) return;
    _requests[index] = _requests[index].copyWith(status: status);
    notifyListeners();
  }
}
