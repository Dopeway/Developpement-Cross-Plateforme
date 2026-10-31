import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/core/models/intervention_request.dart';

void main() {
  test('autorise le cycle normal d’une intervention', () {
    expect(
      RequestStatus.pending.canTransitionTo(RequestStatus.accepted),
      isTrue,
    );
    expect(
      RequestStatus.accepted.canTransitionTo(RequestStatus.inProgress),
      isTrue,
    );
    expect(
      RequestStatus.inProgress.canTransitionTo(RequestStatus.completed),
      isTrue,
    );
  });

  test('autorise le refus ou l’annulation uniquement en attente', () {
    expect(
      RequestStatus.pending.canTransitionTo(RequestStatus.refused),
      isTrue,
    );
    expect(
      RequestStatus.pending.canTransitionTo(RequestStatus.cancelled),
      isTrue,
    );
    expect(
      RequestStatus.accepted.canTransitionTo(RequestStatus.cancelled),
      isFalse,
    );
  });

  test('interdit de revenir à un statut précédent', () {
    expect(
      RequestStatus.completed.canTransitionTo(RequestStatus.inProgress),
      isFalse,
    );
    expect(
      RequestStatus.refused.canTransitionTo(RequestStatus.accepted),
      isFalse,
    );
  });

  test('propose uniquement la prochaine action artisan pertinente', () {
    expect(RequestStatus.pending.nextArtisanStatus, RequestStatus.accepted);
    expect(RequestStatus.accepted.nextArtisanStatus, RequestStatus.inProgress);
    expect(RequestStatus.inProgress.nextArtisanStatus, RequestStatus.completed);
    expect(RequestStatus.completed.nextArtisanStatus, isNull);
  });
}
