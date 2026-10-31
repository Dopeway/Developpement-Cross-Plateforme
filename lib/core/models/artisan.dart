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
  });
  factory Artisan.fromJson(Map<String, Object?> json) => Artisan(
    id: json['id']! as String,
    name: json['name']! as String,
    trade: json['trade']! as String,
    area: json['area']! as String,
    rating: (json['rating']! as num).toDouble(),
    reviewCount: json['reviewCount']! as int,
    startingPrice: json['startingPrice']! as int,
    verified: json['verified']! as bool,
    availableToday: json['availableToday']! as bool,
    verificationStatus: _statusFromJson(json),
    rejectionReason: json['rejectionReason'] as String?,
  );

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
  final String trade;
  final String area;
  final double rating;
  final int reviewCount;
  final int startingPrice;
  final bool verified;
  final bool availableToday;
  final ArtisanVerificationStatus verificationStatus;
  final String? rejectionReason;

  Map<String, Object?> toJson() => {
    'name': name,
    'trade': trade,
    'area': area,
    'rating': rating,
    'reviewCount': reviewCount,
    'startingPrice': startingPrice,
    'verified': verified,
    'availableToday': availableToday,
    'verificationStatus': verificationStatus.name,
    'rejectionReason': rejectionReason,
  };
}
