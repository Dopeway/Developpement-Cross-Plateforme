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
  );
  final String id;
  final String name;
  final String trade;
  final String area;
  final double rating;
  final int reviewCount;
  final int startingPrice;
  final bool verified;
  final bool availableToday;
}
