import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus {
  pending,
  accepted,
  inProgress,
  completed,
  refused,
  cancelled,
}

extension RequestStatusLabel on RequestStatus {
  String get label => switch (this) {
    RequestStatus.pending => 'En attente',
    RequestStatus.accepted => 'Acceptée',
    RequestStatus.inProgress => 'En cours',
    RequestStatus.completed => 'Terminée',
    RequestStatus.refused => 'Refusée',
    RequestStatus.cancelled => 'Annulée',
  };

  bool canTransitionTo(RequestStatus next) => switch (this) {
    RequestStatus.pending =>
      next == RequestStatus.accepted ||
          next == RequestStatus.refused ||
          next == RequestStatus.cancelled,
    RequestStatus.accepted => next == RequestStatus.inProgress,
    RequestStatus.inProgress => next == RequestStatus.completed,
    RequestStatus.completed ||
    RequestStatus.refused ||
    RequestStatus.cancelled => false,
  };

  RequestStatus? get nextArtisanStatus => switch (this) {
    RequestStatus.pending => RequestStatus.accepted,
    RequestStatus.accepted => RequestStatus.inProgress,
    RequestStatus.inProgress => RequestStatus.completed,
    RequestStatus.completed ||
    RequestStatus.refused ||
    RequestStatus.cancelled => null,
  };

  bool get allowsChat =>
      this == RequestStatus.accepted || this == RequestStatus.inProgress;
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
  });
  factory InterventionRequest.fromJson(Map<String, Object?> json) {
    final createdAtValue = json['createdAt'];
    final correctionValue = json['adminCorrection'];
    return InterventionRequest(
      id: json['id']! as String,
      service: json['service']! as String,
      artisanId: json['artisanId']! as String,
      artisanName: json['artisanName']! as String,
      clientId: json['clientId']! as String,
      clientName: json['clientName']! as String,
      description: json['description']! as String,
      address: json['address']! as String,
      date: json['date']! as String,
      status: RequestStatus.values.byName(json['status']! as String),
      createdAt: switch (createdAtValue) {
        Timestamp timestamp => timestamp.toDate(),
        DateTime dateTime => dateTime,
        _ => null,
      },
      adminCorrection: correctionValue is Map<String, dynamic>
          ? AdminStatusCorrection.fromJson(correctionValue)
          : correctionValue is Map<String, Object?>
          ? AdminStatusCorrection.fromJson(correctionValue)
          : null,
    );
  }
  final String id;
  final String service;
  final String artisanId;
  final String artisanName;
  final String clientId;
  final String clientName;
  final String description;
  final String address;
  final String date;
  final RequestStatus status;
  final DateTime? createdAt;
  final AdminStatusCorrection? adminCorrection;

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
  };
}

class AdminStatusCorrection {
  const AdminStatusCorrection({
    required this.previousStatus,
    required this.reason,
    required this.correctedBy,
    required this.correctedAt,
  });

  factory AdminStatusCorrection.fromJson(Map<String, Object?> json) {
    final correctedAtValue = json['correctedAt'];
    return AdminStatusCorrection(
      previousStatus: RequestStatus.values.byName(
        json['previousStatus']! as String,
      ),
      reason: json['reason']! as String,
      correctedBy: json['correctedBy']! as String,
      correctedAt: switch (correctedAtValue) {
        Timestamp timestamp => timestamp.toDate(),
        DateTime dateTime => dateTime,
        _ => null,
      },
    );
  }

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
