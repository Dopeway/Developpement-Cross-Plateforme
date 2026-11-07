import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_slot.dart';

enum RequestStatus {
  pending,
  accepted,
  awaitingQuote,
  quoteAccepted,
  inProgress,
  completed,
  refused,
  cancelled,
  expired,
  rescheduleRequested,
}

extension RequestStatusLabel on RequestStatus {
  String get label => switch (this) {
    RequestStatus.pending => 'En attente de confirmation',
    RequestStatus.accepted => 'Acceptée',
    RequestStatus.awaitingQuote => 'Devis à valider',
    RequestStatus.quoteAccepted => 'Devis accepté',
    RequestStatus.inProgress => 'En cours',
    RequestStatus.completed => 'Terminée',
    RequestStatus.refused => 'Refusée',
    RequestStatus.cancelled => 'Annulée',
    RequestStatus.expired => 'Expirée',
    RequestStatus.rescheduleRequested => 'Report demandé',
  };
  bool canTransitionTo(RequestStatus next) => switch (this) {
    RequestStatus.pending =>
      next == RequestStatus.accepted ||
          next == RequestStatus.refused ||
          next == RequestStatus.cancelled ||
          next == RequestStatus.expired ||
          next == RequestStatus.rescheduleRequested,
    RequestStatus.accepted =>
      next == RequestStatus.awaitingQuote ||
          next == RequestStatus.rescheduleRequested,
    RequestStatus.awaitingQuote => next == RequestStatus.quoteAccepted,
    RequestStatus.quoteAccepted => next == RequestStatus.inProgress,
    RequestStatus.inProgress => next == RequestStatus.completed,
    RequestStatus.rescheduleRequested =>
      next == RequestStatus.accepted || next == RequestStatus.cancelled,
    _ => false,
  };
  RequestStatus? get nextArtisanStatus => switch (this) {
    RequestStatus.pending => RequestStatus.accepted,
    RequestStatus.accepted => RequestStatus.awaitingQuote,
    RequestStatus.quoteAccepted => RequestStatus.inProgress,
    RequestStatus.inProgress => RequestStatus.completed,
    _ => null,
  };
  bool get allowsChat =>
      this == RequestStatus.accepted ||
      this == RequestStatus.awaitingQuote ||
      this == RequestStatus.quoteAccepted ||
      this == RequestStatus.inProgress;
}

class InterventionRequest {
  const InterventionRequest({
    required this.id,
    required this.service,
    required this.artisanId,
    required this.artisanName,
    required this.clientId,
    required this.clientName,
    required this.description,
    required this.address,
    required this.date,
    required this.status,
    this.createdAt,
    this.adminCorrection,
    this.booking,
    this.addressId,
    this.addressLabel,
    this.quoteAmount,
    this.refusalReason,
  });
  factory InterventionRequest.fromJson(Map<String, Object?> json) {
    final correction = json['adminCorrection'];
    final booking = json['booking'];
    return InterventionRequest(
      id: json['id']! as String,
      service: json['service']! as String,
      artisanId: json['artisanId']! as String,
      artisanName: json['artisanName']! as String,
      clientId: json['clientId']! as String,
      clientName: json['clientName']! as String,
      description: json['description']! as String,
      address: json['address']! as String,
      date: json['date'] as String? ?? '',
      status: RequestStatus.values.byName(json['status']! as String),
      createdAt: _date(json['createdAt']),
      adminCorrection: correction is Map
          ? AdminStatusCorrection.fromJson(
              Map<String, Object?>.from(correction),
            )
          : null,
      booking: booking is Map
          ? BookingSlot.fromJson(Map<String, Object?>.from(booking))
          : null,
      addressId: json['addressId'] as String?,
      addressLabel: json['addressLabel'] as String?,
      quoteAmount: json['quoteAmount'] as int?,
      refusalReason: json['refusalReason'] as String?,
    );
  }
  final String id;
  final String service;
  final String artisanId;
  final String artisanName;
  final String clientId;
  final String clientName;
  final String description;

  /// Zone visible avant acceptation; l'adresse complète reste privée.
  final String address;
  final String date;
  final RequestStatus status;
  final DateTime? createdAt;
  final AdminStatusCorrection? adminCorrection;
  final BookingSlot? booking;
  final String? addressId;
  final String? addressLabel;
  final int? quoteAmount;
  final String? refusalReason;
  InterventionRequest copyWith({RequestStatus? status}) => InterventionRequest(
    id: id,
    service: service,
    artisanId: artisanId,
    artisanName: artisanName,
    clientId: clientId,
    clientName: clientName,
    description: description,
    address: address,
    date: date,
    status: status ?? this.status,
    createdAt: createdAt,
    adminCorrection: adminCorrection,
    booking: booking,
    addressId: addressId,
    addressLabel: addressLabel,
    quoteAmount: quoteAmount,
    refusalReason: refusalReason,
  );
  Map<String, Object> toJson() => {
    'service': service,
    'artisanId': artisanId,
    'artisanName': artisanName,
    'clientId': clientId,
    'clientName': clientName,
    'description': description,
    'address': address,
    'date': date,
    'status': status.name,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (adminCorrection != null) 'adminCorrection': adminCorrection!.toJson(),
    if (booking != null) 'booking': booking!.toJson(),
    'addressId': ?addressId,
    'addressLabel': ?addressLabel,
    'quoteAmount': ?quoteAmount,
    'refusalReason': ?refusalReason,
  };
}

class AdminStatusCorrection {
  const AdminStatusCorrection({
    required this.previousStatus,
    required this.reason,
    required this.correctedBy,
    required this.correctedAt,
  });
  factory AdminStatusCorrection.fromJson(Map<String, Object?> json) =>
      AdminStatusCorrection(
        previousStatus: RequestStatus.values.byName(
          json['previousStatus']! as String,
        ),
        reason: json['reason']! as String,
        correctedBy: json['correctedBy']! as String,
        correctedAt: _date(json['correctedAt']),
      );
  final RequestStatus previousStatus;
  final String reason;
  final String correctedBy;
  final DateTime? correctedAt;
  Map<String, Object> toJson() => {
    'previousStatus': previousStatus.name,
    'reason': reason,
    'correctedBy': correctedBy,
    if (correctedAt != null) 'correctedAt': Timestamp.fromDate(correctedAt!),
  };
}

DateTime? _date(Object? value) => switch (value) {
  Timestamp timestamp => timestamp.toDate(),
  DateTime dateTime => dateTime,
  _ => null,
};
