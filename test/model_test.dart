import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/app_user.dart';
import 'package:quickfix_tunisia/core/models/artisan.dart';
import 'package:quickfix_tunisia/core/models/intervention_request.dart';

void main() {
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
      trade: 'Plomberie',
      area: 'Tunis',
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
  });
}
