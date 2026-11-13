import 'artisan_catalog.dart';
import 'availability.dart';

enum ArtisanVerificationStatus { pending, verified, refused, suspended }

extension ArtisanVerificationStatusLabel on ArtisanVerificationStatus {
  String get label => switch (this) {
    ArtisanVerificationStatus.pending => 'En attente de validation',
    ArtisanVerificationStatus.verified => 'Profil vérifié',
    ArtisanVerificationStatus.refused => 'Validation refusée',
    ArtisanVerificationStatus.suspended => 'Profil suspendu',
  };
}

class Artisan {
  const Artisan({
    required this.id,
    required this.name,
    required this.trade,
    required this.area,
    required this.rating,
    required this.reviewCount,
    required this.startingPrice,
    required this.verified,
    required this.availableToday,
    this.verificationStatus = ArtisanVerificationStatus.pending,
    this.rejectionReason,
    this.availabilityRules = const [],
    this.availabilityExceptions = const [],
    this.defaultDurationMinutes = 60,
  });
  factory Artisan.fromJson(Map<String, Object?> json) => Artisan(
    id: json['id']! as String,
    name: json['name']! as String,
    trade: ArtisanTrade.fromStorageValue(json['trade']! as String),
    area: InterventionArea.fromStorageValue(json['area']! as String),
    rating: (json['rating']! as num).toDouble(),
    reviewCount: json['reviewCount']! as int,
    startingPrice: json['startingPrice']! as int,
    verified: json['verified']! as bool,
    availableToday: json['availableToday']! as bool,
    verificationStatus: _statusFromJson(json),
    rejectionReason: json['rejectionReason'] as String?,
    availabilityRules: _rulesFromJson(json['availabilityRules']),
    availabilityExceptions: _exceptionsFromJson(json['availabilityExceptions']),
    defaultDurationMinutes: json['defaultDurationMinutes'] as int? ?? 60,
  );

  static List<AvailabilityRule> _rulesFromJson(Object? value) =>
      (value as List<Object?>? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(
            (item) =>
                AvailabilityRule.fromJson(Map<String, Object?>.from(item)),
          )
          .where((rule) => rule.isValid)
          .toList();

  static List<AvailabilityException> _exceptionsFromJson(Object? value) =>
      (value as List<Object?>? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(
            (item) =>
                AvailabilityException.fromJson(Map<String, Object?>.from(item)),
          )
          .where((exception) => exception.parsedDate != null)
          .toList();

  static ArtisanVerificationStatus _statusFromJson(Map<String, Object?> json) {
    final status = json['verificationStatus'] as String?;
    if (status != null) {
      return ArtisanVerificationStatus.values.byName(status);
    }
    return json['verified']! as bool
        ? ArtisanVerificationStatus.verified
        : ArtisanVerificationStatus.pending;
  }

  final String id;
  final String name;
  final ArtisanTrade trade;
  final InterventionArea area;
  final double rating;
  final int reviewCount;
  final int startingPrice;
  final bool verified;
  final bool availableToday;
  final ArtisanVerificationStatus verificationStatus;
  final String? rejectionReason;
  final List<AvailabilityRule> availabilityRules;
  final List<AvailabilityException> availabilityExceptions;
  final int defaultDurationMinutes;

  Map<String, Object?> toJson() => {
    'name': name,
    'trade': trade.storageValue,
    'area': area.storageValue,
    'rating': rating,
    'reviewCount': reviewCount,
    'startingPrice': startingPrice,
    'verified': verified,
    'availableToday': availableToday,
    'verificationStatus': verificationStatus.name,
    'rejectionReason': rejectionReason,
    if (availabilityRules.isNotEmpty)
      'availabilityRules': availabilityRules
          .map((rule) => rule.toJson())
          .toList(),
    if (availabilityExceptions.isNotEmpty)
      'availabilityExceptions': availabilityExceptions
          .map((exception) => exception.toJson())
          .toList(),
    'defaultDurationMinutes': defaultDurationMinutes,
  };
}
