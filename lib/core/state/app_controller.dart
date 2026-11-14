import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../features/artisans/data/artisan_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/profile_registration_repository.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/request/data/request_repository.dart';
import '../../features/reviews/data/review_repository.dart';
import '../../features/users/data/user_repository.dart';
import '../models/app_user.dart';
import '../models/app_notification.dart';
import '../models/artisan.dart';
import '../models/booking_slot.dart';
import '../models/availability.dart';
import '../models/artisan_catalog.dart';
import '../models/chat_message.dart';
import '../models/intervention_request.dart';
import '../models/review.dart';
import '../models/saved_address.dart';
import '../services/availability_calculator.dart';

class AppController extends ChangeNotifier {
  AppController({
    AuthRepository? authRepository,
    ProfileRegistrationRepository? profileRegistrationRepository,
    UserRepository? userRepository,
    ArtisanRepository? artisanRepository,
    RequestRepository? requestRepository,
    ChatRepository? chatRepository,
    ReviewRepository? reviewRepository,
    NotificationRepository? notificationRepository,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _profileRegistrationRepository =
           profileRegistrationRepository ?? ProfileRegistrationRepository(),
       _userRepository = userRepository ?? UserRepository(),
       _artisanRepository = artisanRepository ?? ArtisanRepository(),
       _requestRepository = requestRepository ?? RequestRepository(),
       _chatRepository = chatRepository ?? ChatRepository(),
       _reviewRepository = reviewRepository ?? ReviewRepository(),
       _notificationRepository =
           notificationRepository ?? NotificationRepository() {
    _authSubscription = _authRepository.authStateChanges.listen(_onAuthChanged);
  }

  final AuthRepository _authRepository;
  final ProfileRegistrationRepository _profileRegistrationRepository;
  final UserRepository _userRepository;
  final ArtisanRepository _artisanRepository;
  final RequestRepository _requestRepository;
  final ChatRepository _chatRepository;
  final ReviewRepository _reviewRepository;
  final NotificationRepository _notificationRepository;
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
  Stream<List<ChatMessage>> chatMessages(InterventionRequest request) {
    _ensureChatAccess(request);
    return _chatRepository.watchMessages(request.id);
  }

  Stream<List<AppUser>> get users => _userRepository.watchUsers();
  Stream<List<SavedAddress>> get savedAddresses => _currentUser == null
      ? Stream<List<SavedAddress>>.value(const [])
      : _userRepository.watchAddresses(_currentUser!.id);
  Stream<List<Review>> reviewsForArtisan(String id) =>
      _reviewRepository.watchForArtisan(id);
  Stream<List<AppNotification>> get notifications => _currentUser == null
      ? Stream<List<AppNotification>>.value(const [])
      : _notificationRepository.watchForUser(_currentUser!.id);
  Stream<int> get unreadNotificationCount => _currentUser == null
      ? Stream<int>.value(0)
      : _notificationRepository.watchUnreadCount(_currentUser!.id);

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
    ArtisanTrade? trade,
    InterventionArea? area,
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
    if (existingUser != null && existingUser.role != role) {
      throw StateError(
        'Cette adresse e-mail est déjà utilisée par un compte ${existingUser.role.label.toLowerCase()}.',
      );
    }
    Artisan? existingArtisan;
    if (role == UserRole.artisan) {
      existingArtisan = await _artisanRepository.getArtisan(user.uid);
    }
    await _profileRegistrationRepository.completeRegistration(
      user: AppUser(
        id: user.uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
      ),
      artisan: role == UserRole.artisan
          ? Artisan(
              id: user.uid,
              name: name.trim(),
              trade: trade!,
              area: area!,
              rating: 0,
              reviewCount: 0,
              startingPrice: startingPrice!,
              verified: false,
              availableToday: true,
              verificationStatus: ArtisanVerificationStatus.pending,
            )
          : null,
      createUser: existingUser == null,
      createArtisan: role == UserRole.artisan && existingArtisan == null,
    );
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
    required String addressId,
    required DateTime start,
    required DateTime end,
  }) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.client) {
      throw StateError('Seul un client peut créer une demande.');
    }
    final address = await _userRepository.getAddress(user.id, addressId);
    if (address == null) throw StateError('Adresse introuvable.');
    await _requestRepository.create(
      client: user,
      artisan: artisan,
      description: description,
      address: address.fullAddress,
      slot: start.toIso8601String(),
    );
  }

  Future<List<BookingSlot>> availableSlots({
    required String artisanId,
    required DateTime day,
  }) async {
    final artisan = await _artisanRepository.getArtisan(artisanId);
    if (artisan == null || !artisan.verified) return const [];
    return availableSlotsForArtisan(artisan: artisan, day: day);
  }

  Future<Set<String>> availableBookingDays({
    required String artisanId,
    required DateTime startDay,
    required int days,
  }) async {
    final artisan = await _artisanRepository.getArtisan(artisanId);
    if (artisan == null || !artisan.verified) return const {};
    return {
      for (var index = 0; index < days; index++)
        if (availableSlotsForArtisan(
          artisan: artisan,
          day: startDay.add(Duration(days: index)),
        ).isNotEmpty)
          _dateKey(startDay.add(Duration(days: index))),
    };
  }

  String _dateKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<void> updateRequestStatus(
    String id,
    RequestStatus status, {
    int? quoteAmount,
  }) async {
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
    if (isClient &&
        !((request.status == RequestStatus.pending &&
                status == RequestStatus.cancelled) ||
            (request.status == RequestStatus.awaitingQuote &&
                (status == RequestStatus.accepted ||
                    status == RequestStatus.quoteRefused)))) {
      throw StateError('Cette action client n’est pas autorisée.');
    }
    if (isArtisan &&
        !((request.status == RequestStatus.pending &&
                (status == RequestStatus.awaitingQuote ||
                    status == RequestStatus.refused)) ||
            ((request.status == RequestStatus.accepted ||
                    request.status == RequestStatus.quoteAccepted) &&
                status == RequestStatus.inProgress) ||
            (request.status == RequestStatus.inProgress &&
                status == RequestStatus.completed))) {
      throw StateError('Cette action artisan n’est pas autorisée.');
    }
    if (status == RequestStatus.awaitingQuote &&
        (quoteAmount == null || quoteAmount < 0)) {
      throw ArgumentError('Un montant de devis valide est requis.');
    }
    if (status != RequestStatus.awaitingQuote && quoteAmount != null) {
      throw ArgumentError(
        'Le montant ne peut être modifié qu’à l’envoi du devis.',
      );
    }
    await _requestRepository.updateStatus(
      id: id,
      status: status,
      quoteAmount: quoteAmount,
    );
  }

  Future<void> correctRequestStatus({
    required InterventionRequest request,
    required RequestStatus status,
    required String reason,
  }) async {
    final user = _currentUser;
    final normalizedReason = reason.trim();
    if (user == null || user.role != UserRole.admin) {
      throw StateError('Seul un administrateur peut corriger une demande.');
    }
    if (normalizedReason.length < 10 || normalizedReason.length > 280) {
      throw ArgumentError('Le motif doit contenir entre 10 et 280 caractères.');
    }
    await _requestRepository.correctStatus(
      id: request.id,
      status: status,
      previousStatus: request.status,
      reason: normalizedReason,
      correctedBy: user.id,
    );
  }

  Future<InterventionRequest?> getRequest(String id) =>
      _requestRepository.get(id);

  Future<void> sendChatMessage({
    required InterventionRequest request,
    required String content,
  }) async {
    _ensureChatAccess(request);
    final message = content.trim();
    if (message.isEmpty || message.length > 1000) {
      throw ArgumentError(
        'Le message doit contenir entre 1 et 1000 caractères.',
      );
    }
    final user = _currentUser!;
    await _chatRepository.send(
      requestId: request.id,
      senderId: user.id,
      senderName: user.name,
      content: message,
    );
  }

  void _ensureChatAccess(InterventionRequest request) {
    final user = _currentUser;
    final isParticipant =
        user != null &&
        (request.clientId == user.id || request.artisanId == user.id);
    if (!isParticipant || !request.status.allowsChat) {
      throw StateError('Cette discussion n’est pas disponible.');
    }
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
    required ArtisanTrade trade,
    required InterventionArea area,
    required int startingPrice,
  }) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.artisan) {
      throw StateError('Seul un artisan peut modifier ce profil.');
    }
    if (name.trim().length < 2) {
      throw ArgumentError('Les informations du profil sont incomplètes.');
    }
    if (startingPrice < 0) throw ArgumentError('Le tarif est invalide.');
    await _artisanRepository.updateProfile(
      id: user.id,
      name: name,
      trade: trade,
      area: area,
      startingPrice: startingPrice,
    );
  }

  Future<void> updateArtisanAvailability({
    required List<AvailabilityRule> rules,
    required List<AvailabilityException> exceptions,
    required int defaultDurationMinutes,
  }) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.artisan) {
      throw StateError('Seul un artisan peut modifier ses disponibilités.');
    }
    if (rules.any((rule) => !rule.isValid) ||
        defaultDurationMinutes < 15 ||
        defaultDurationMinutes > 240) {
      throw ArgumentError('Le planning contient des horaires invalides.');
    }
    for (var index = 0; index < rules.length; index++) {
      for (
        var otherIndex = index + 1;
        otherIndex < rules.length;
        otherIndex++
      ) {
        if (rules[index].overlaps(rules[otherIndex])) {
          throw ArgumentError('Deux plages horaires se chevauchent.');
        }
      }
    }
    await _artisanRepository.updateAvailability(
      id: user.id,
      rules: rules,
      exceptions: exceptions,
      defaultDurationMinutes: defaultDurationMinutes,
    );
  }

  Future<void> createArtisanProfile({
    required String name,
    required ArtisanTrade trade,
    required InterventionArea area,
    required int startingPrice,
  }) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.artisan) {
      throw StateError('Seul un artisan peut créer ce profil.');
    }
    if (name.trim().length < 2 || startingPrice < 0) {
      throw ArgumentError('Les informations du profil sont incomplètes.');
    }
    await _artisanRepository.createArtisanProfile(
      id: user.id,
      name: name,
      trade: trade,
      area: area,
      startingPrice: startingPrice,
    );
  }

  Future<void> updateUserName(String name) async {
    final user = _currentUser;
    if (user == null || name.trim().length < 2) {
      throw ArgumentError('Le nom est invalide.');
    }
    await _userRepository.updateProfile(user.copyWith(name: name.trim()));
  }

  Future<void> addSavedAddress(String value) async {
    final user = _currentUser;
    final normalizedValue = value.trim();
    if (user == null || user.role != UserRole.client) {
      throw StateError('Seul un client peut enregistrer une adresse.');
    }
    if (normalizedValue.length < 5 || normalizedValue.length > 200) {
      throw ArgumentError('Indiquez une adresse entre 5 et 200 caractères.');
    }
    await _userRepository.addAddress(user.id, normalizedValue);
  }

  Future<void> deleteSavedAddress(String addressId) async {
    final user = _currentUser;
    if (user == null || user.role != UserRole.client) {
      throw StateError('Seul un client peut supprimer une adresse.');
    }
    await _userRepository.deleteAddress(user.id, addressId);
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

  Future<void> markNotificationAsRead(String notificationId) =>
      _notificationRepository.markAsRead(notificationId);

  Future<void> markAllNotificationsAsRead() {
    final user = _currentUser;
    if (user == null) throw StateError('Connexion requise.');
    return _notificationRepository.markAllAsRead(user.id);
  }

  Future<void> logout() => _authRepository.signOut();

  @override
  void dispose() {
    _authSubscription.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
