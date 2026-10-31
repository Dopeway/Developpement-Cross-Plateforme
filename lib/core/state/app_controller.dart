import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../features/artisans/data/artisan_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/request/data/request_repository.dart';
import '../../features/reviews/data/review_repository.dart';
import '../../features/users/data/user_repository.dart';
import '../models/app_user.dart';
import '../models/artisan.dart';
import '../models/intervention_request.dart';
import '../models/review.dart';

class AppController extends ChangeNotifier {
  AppController({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    ArtisanRepository? artisanRepository,
    RequestRepository? requestRepository,
    ReviewRepository? reviewRepository,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _userRepository = userRepository ?? UserRepository(),
       _artisanRepository = artisanRepository ?? ArtisanRepository(),
       _requestRepository = requestRepository ?? RequestRepository(),
       _reviewRepository = reviewRepository ?? ReviewRepository() {
    _authSubscription = _authRepository.authStateChanges.listen(_onAuthChanged);
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final ArtisanRepository _artisanRepository;
  final RequestRepository _requestRepository;
  final ReviewRepository _reviewRepository;
  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<AppUser?>? _userSubscription;
  AppUser? _currentUser;
  bool _authResolved = false;

  AppUser? get currentUser => _currentUser;
  bool get authResolved => _authResolved;
  Stream<List<Artisan>> get artisans => _artisanRepository.watchArtisans();
  Stream<List<Artisan>> get pendingArtisans =>
      _artisanRepository.watchPendingArtisans();
  Stream<Artisan?> get artisanProfile => _currentUser == null
      ? Stream<Artisan?>.value(null)
      : _artisanRepository.watchArtisan(_currentUser!.id);
  Stream<List<InterventionRequest>> get requests => _currentUser == null
      ? Stream<List<InterventionRequest>>.value(const [])
      : _requestRepository.watchForUser(_currentUser!);
  Stream<List<AppUser>> get users => _userRepository.watchUsers();
  Stream<List<Review>> reviewsForArtisan(String id) =>
      _reviewRepository.watchForArtisan(id);

  void _onAuthChanged(User? firebaseUser) {
    _userSubscription?.cancel();
    _currentUser = null;
    _authResolved = true;
    if (firebaseUser == null) {
      notifyListeners();
      return;
    }
    _userSubscription = _userRepository.watchUser(firebaseUser.uid).listen((
      user,
    ) {
      _currentUser = user;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) =>
      _authRepository.signIn(email: email, password: password);

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? trade,
    String? area,
    int? startingPrice,
  }) async {
    if (role == UserRole.admin) {
      throw ArgumentError('Le rôle administrateur ne peut pas être créé ici.');
    }
    if (role == UserRole.artisan &&
        (trade == null || area == null || startingPrice == null)) {
      throw ArgumentError('Les informations professionnelles sont requises.');
    }
    final user = await _registerOrSignIn(email: email, password: password);
    final existingUser = await _userRepository.getUser(user.uid);
    if (existingUser == null) {
      await _userRepository.createUser(
        id: user.uid,
        name: name,
        email: email,
        role: role,
      );
    } else if (existingUser.role != role) {
      throw StateError(
        'Cette adresse e-mail est déjà utilisée par un compte ${existingUser.role.label.toLowerCase()}.',
      );
    }
    if (role == UserRole.artisan) {
      final existingArtisan = await _artisanRepository.getArtisan(user.uid);
      if (existingArtisan == null) {
        await _artisanRepository.createArtisanProfile(
          id: user.uid,
          name: name,
          trade: trade!,
          area: area!,
          startingPrice: startingPrice!,
        );
      }
    }
  }

  Future<User> _registerOrSignIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _authRepository.register(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;
      return _authRepository.signIn(email: email, password: password);
    }
  }

  Future<void> createRequest({
    required Artisan artisan,
    required String description,
    required String address,
    required String slot,
  }) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.client) {
      throw StateError('Seul un client peut créer une demande.');
    }
    await _requestRepository.create(
      client: user,
      artisan: artisan,
      description: description,
      address: address,
      slot: slot,
    );
  }

  Future<void> updateRequestStatus(String id, RequestStatus status) async {
    final user = _currentUser;
    if (user == null) throw StateError('Connexion requise.');
    final request = await _requestRepository.get(id);
    if (request == null) throw StateError('Demande introuvable.');
    final isAdmin = user.role == UserRole.admin;
    final isClient =
        user.role == UserRole.client && request.clientId == user.id;
    final isArtisan =
        user.role == UserRole.artisan && request.artisanId == user.id;
    if (!isAdmin && !isClient && !isArtisan) {
      throw StateError('Vous ne pouvez pas modifier cette demande.');
    }
    if (!isAdmin && !request.status.canTransitionTo(status)) {
      throw StateError('Cette transition n’est pas autorisée.');
    }
    if (isClient && status != RequestStatus.cancelled) {
      throw StateError('Le client peut uniquement annuler une demande.');
    }
    await _requestRepository.updateStatus(id: id, status: status);
  }

  Future<void> updateArtisanVerification(
    String id,
    ArtisanVerificationStatus status, {
    String? rejectionReason,
  }) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.admin) {
      throw StateError('Seul un administrateur peut valider un artisan.');
    }
    await _artisanRepository.updateVerification(
      id: id,
      status: status,
      rejectionReason: rejectionReason,
    );
  }

  Future<void> updateArtisanProfile({
    required String name,
    required String trade,
    required String area,
    required int startingPrice,
    required bool availableToday,
  }) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.artisan) {
      throw StateError('Seul un artisan peut modifier ce profil.');
    }
    if (name.trim().length < 2 ||
        trade.trim().length < 2 ||
        area.trim().length < 2) {
      throw ArgumentError('Les informations du profil sont incomplètes.');
    }
    if (startingPrice < 0) throw ArgumentError('Le tarif est invalide.');
    await _artisanRepository.updateProfile(
      id: user.id,
      name: name,
      trade: trade,
      area: area,
      startingPrice: startingPrice,
      availableToday: availableToday,
    );
  }

  Future<void> updateUserName(String name) async {
    final user = _currentUser;
    if (user == null || name.trim().length < 2) {
      throw ArgumentError('Le nom est invalide.');
    }
    await _userRepository.updateProfile(user.copyWith(name: name.trim()));
  }

  Future<void> createReview({
    required InterventionRequest request,
    required int rating,
    required String comment,
  }) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.client) {
      throw StateError('Seul un client peut donner un avis.');
    }
    if (request.clientId != user.id ||
        request.status != RequestStatus.completed) {
      throw StateError('Cette demande ne peut pas recevoir d’avis.');
    }
    if (rating < 1 || rating > 5 || comment.trim().isEmpty) {
      throw ArgumentError('La note et le commentaire sont requis.');
    }
    if (await _reviewRepository.existsForRequest(request.id)) {
      throw StateError('Un avis existe déjà pour cette demande.');
    }
    await _reviewRepository.create(
      request: request,
      rating: rating,
      comment: comment,
    );
  }

  Future<void> logout() => _authRepository.signOut();

  @override
  void dispose() {
    _authSubscription.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
