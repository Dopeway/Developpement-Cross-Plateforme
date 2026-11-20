import 'package:cloud_firestore/cloud_firestore.dart';

/// Snapshot of the agreed service, kept unchanged after publication.
class BillingDocument {
  const BillingDocument({
    required this.requestId,
    required this.artisanId,
    required this.clientId,
    required this.issuerName,
    required this.issuerAddress,
    required this.taxId,
    required this.vatRate,
    required this.clientName,
    required this.clientAddress,
    required this.service,
    required this.workPerformed,
    required this.serviceDate,
    required this.totalMillimes,
    this.diagnosis,
    this.materials,
    this.clientAdvice,
    this.createdAt,
  });

  factory BillingDocument.fromJson(Map<String, Object?> json) =>
      BillingDocument(
        requestId: json['requestId']! as String,
        artisanId: json['artisanId']! as String,
        clientId: json['clientId']! as String,
        issuerName: json['issuerName']! as String,
        issuerAddress: json['issuerAddress']! as String,
        taxId: json['taxId']! as String,
        vatRate: json['vatRate']! as int,
        clientName: json['clientName']! as String,
        clientAddress: json['clientAddress']! as String,
        service: json['service']! as String,
        workPerformed: json['workPerformed']! as String,
        serviceDate: json['serviceDate']! as String,
        totalMillimes: json['totalMillimes']! as int,
        diagnosis: json['diagnosis'] as String?,
        materials: json['materials'] as String?,
        clientAdvice: json['clientAdvice'] as String?,
        createdAt: switch (json['createdAt']) {
          Timestamp value => value.toDate(),
          DateTime value => value,
          _ => null,
        },
      );

  final String requestId;
  final String artisanId;
  final String clientId;
  final String issuerName;
  final String issuerAddress;
  final String taxId;

  /// Percentage. Zero means that no VAT is applied.
  final int vatRate;
  final String clientName;
  final String clientAddress;
  final String service;
  final String workPerformed;
  final String serviceDate;
  final int totalMillimes;
  final String? diagnosis;
  final String? materials;
  final String? clientAdvice;
  final DateTime? createdAt;

  int get subtotalMillimes =>
      (totalMillimes * 100 + (100 + vatRate) ~/ 2) ~/ (100 + vatRate);

  int get vatMillimes => totalMillimes - subtotalMillimes;

  Map<String, Object?> toJson() => {
    'requestId': requestId,
    'artisanId': artisanId,
    'clientId': clientId,
    'issuerName': issuerName.trim(),
    'issuerAddress': issuerAddress.trim(),
    'taxId': taxId.trim(),
    'vatRate': vatRate,
    'clientName': clientName.trim(),
    'clientAddress': clientAddress.trim(),
    'service': service.trim(),
    'workPerformed': workPerformed.trim(),
    'serviceDate': serviceDate,
    'totalMillimes': totalMillimes,
    'diagnosis': diagnosis?.trim() ?? '',
    'materials': materials?.trim() ?? '',
    'clientAdvice': clientAdvice?.trim() ?? '',
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
  };
}
