import 'package:cloud_firestore/cloud_firestore.dart';

class InterventionReport {
  const InterventionReport({
    required this.workPerformed,
    this.diagnosis,
    this.materials,
    this.clientAdvice,
    this.completedAt,
  });

  factory InterventionReport.fromJson(Map<String, Object?> json) =>
      InterventionReport(
        workPerformed: json['workPerformed'] as String? ?? '',
        diagnosis: json['diagnosis'] as String?,
        materials: json['materials'] as String?,
        clientAdvice: json['clientAdvice'] as String?,
        completedAt: switch (json['completedAt']) {
          Timestamp value => value.toDate(),
          DateTime value => value,
          _ => null,
        },
      );

  final String workPerformed;
  final String? diagnosis;
  final String? materials;
  final String? clientAdvice;
  final DateTime? completedAt;

  Map<String, Object?> toJson() => {
    'workPerformed': workPerformed.trim(),
    if (_hasText(diagnosis)) 'diagnosis': diagnosis!.trim(),
    if (_hasText(materials)) 'materials': materials!.trim(),
    if (_hasText(clientAdvice)) 'clientAdvice': clientAdvice!.trim(),
    if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
  };
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
