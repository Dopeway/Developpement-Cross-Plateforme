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
  });
  factory InterventionRequest.fromJson(Map<String, Object?> json) =>
      InterventionRequest(
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
      );
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
  );
}
