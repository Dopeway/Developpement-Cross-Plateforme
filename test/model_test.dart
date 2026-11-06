import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/app_user.dart';
import 'package:quickfix_tunisia/core/models/app_notification.dart';
import 'package:quickfix_tunisia/core/models/artisan.dart';
import 'package:quickfix_tunisia/core/models/artisan_catalog.dart';
import 'package:quickfix_tunisia/core/models/chat_message.dart';
import 'package:quickfix_tunisia/core/models/intervention_request.dart';
import 'package:quickfix_tunisia/features/request/data/request_repository.dart';

void main() {
  test('trie les demandes datées avant les demandes historiques', () {
    final requests = <InterventionRequest>[
      _request(id: 'legacy'),
      _request(id: 'older', createdAt: DateTime(2026, 11, 5)),
      _request(id: 'newer', createdAt: DateTime(2026, 11, 6)),
    ];

    RequestRepository.sortByNewest(requests);

    expect(requests.map((request) => request.id), ['newer', 'older', 'legacy']);
  });

  test('désérialise la date et la correction administrative d’une demande', () {
    final request = InterventionRequest.fromJson(<String, Object?>{
      'id': 'request-1',
      'service': 'Plomberie',
      'artisanId': 'artisan-1',
      'artisanName': 'Mehdi Artisan',
      'clientId': 'client-1',
      'clientName': 'Amira Cliente',
      'description': 'Fuite sous l’évier.',
      'address': 'Menzah 5',
      'date': 'Demain · 09:00',
      'status': 'completed',
      'createdAt': Timestamp.fromDate(DateTime(2026, 11, 6)),
      'adminCorrection': <String, Object?>{
        'previousStatus': 'inProgress',
        'reason': 'Correction après vérification du support.',
        'correctedBy': 'admin-1',
        'correctedAt': Timestamp.fromDate(DateTime(2026, 11, 6)),
      },
    });

    expect(request.createdAt, DateTime(2026, 11, 6));
    expect(request.adminCorrection?.previousStatus, RequestStatus.inProgress);
    expect(request.adminCorrection?.correctedBy, 'admin-1');
  });

  test('désérialise une demande Firestore', () {
    final request = InterventionRequest.fromJson(const <String, Object?>{
      'id': 'request-1',
      'service': 'Plomberie',
      'artisanId': 'artisan-1',
      'artisanName': 'Sami Ben Salem',
      'clientId': 'client-1',
      'clientName': 'Amira Khalfallah',
      'description': 'Fuite sous évier.',
      'address': 'Tunis',
      'date': 'Demain · 09:00',
      'status': 'pending',
    });

    expect(request.id, 'request-1');
    expect(request.status, RequestStatus.pending);
    expect(request.toJson()['status'], 'pending');
  });

  test('sérialise un profil artisan', () {
    const user = AppUser(
      id: 'artisan-1',
      name: 'Sami Ben Salem',
      email: 'sami@example.tn',
      role: UserRole.artisan,
    );

    final parsed = AppUser.fromJson(<String, Object?>{
      'id': user.id,
      ...user.toJson(),
    });

    expect(parsed.role, UserRole.artisan);
    expect(parsed.name, 'Sami Ben Salem');
  });

  test('sérialise une fiche artisan en attente de validation', () {
    const artisan = Artisan(
      id: 'artisan-1',
      name: 'Sami Ben Salem',
      trade: ArtisanTrade.plumber,
      area: InterventionArea.tunis,
      rating: 0,
      reviewCount: 0,
      startingPrice: 50,
      verified: false,
      availableToday: true,
    );

    final parsed = Artisan.fromJson(<String, Object?>{
      'id': artisan.id,
      ...artisan.toJson(),
    });

    expect(parsed.verified, isFalse);
    expect(parsed.startingPrice, 50);
    expect(parsed.trade, ArtisanTrade.plumber);
    expect(parsed.area, InterventionArea.tunis);
    expect(artisan.toJson()['trade'], 'plumber');
    expect(artisan.toJson()['area'], 'tunis');
  });

  test('lit les anciennes valeurs métier et zone pendant la migration', () {
    expect(ArtisanTrade.fromStorageValue('Plomberie'), ArtisanTrade.plumber);
    expect(InterventionArea.fromStorageValue('Tunis'), InterventionArea.tunis);
  });

  test('désérialise une notification persistée', () {
    final notification = AppNotification.fromJson(const <String, Object?>{
      'id': 'notification-1',
      'recipientId': 'client-1',
      'type': 'interventionCompleted',
      'title': 'Intervention terminée',
      'message': 'Vous pouvez maintenant donner votre avis.',
      'isRead': false,
      'requestId': 'request-1',
    });

    expect(notification.type, AppNotificationType.interventionCompleted);
    expect(notification.isRead, isFalse);
    expect(notification.requestId, 'request-1');

    final chatNotification = AppNotification.fromJson(const <String, Object?>{
      'id': 'notification-2',
      'recipientId': 'artisan-1',
      'type': 'chatMessage',
      'title': 'Nouveau message',
      'message': 'Vous avez reçu un message.',
      'isRead': false,
    });

    expect(chatNotification.type, AppNotificationType.chatMessage);
  });

  test('deserializes a chat message', () {
    final message = ChatMessage.fromJson(<String, Object?>{
      'id': 'message-1',
      'senderId': 'client-1',
      'senderName': 'Amira Khalfallah',
      'content': 'Je serai disponible a 16h.',
      'createdAt': DateTime(2026, 11, 6, 16),
    });

    expect(message.senderId, 'client-1');
    expect(message.createdAt, DateTime(2026, 11, 6, 16));
  });
}

InterventionRequest _request({required String id, DateTime? createdAt}) =>
    InterventionRequest(
      id: id,
      service: 'Plomberie',
      artisanId: 'artisan-1',
      artisanName: 'Sami',
      clientId: 'client-1',
      clientName: 'Amira',
      description: 'Fuite sous évier.',
      address: 'Tunis',
      date: 'Demain',
      status: RequestStatus.pending,
      createdAt: createdAt,
    );
