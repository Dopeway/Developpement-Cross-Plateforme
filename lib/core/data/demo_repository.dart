import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/app_user.dart';
import '../models/artisan.dart';
import '../models/intervention_request.dart';

class DemoRepository {
  const DemoRepository();

  Future<DemoSeed> load() async {
    final raw = await rootBundle.loadString('assets/data/demo_data.json');
    final json = jsonDecode(raw) as Map<String, Object?>;
    return DemoSeed(
      users: (json['users']! as List<Object?>)
          .map((item) => AppUser.fromJson(item! as Map<String, Object?>))
          .toList(),
      artisans: (json['artisans']! as List<Object?>)
          .map((item) => Artisan.fromJson(item! as Map<String, Object?>))
          .toList(),
      requests: (json['requests']! as List<Object?>)
          .map(
            (item) =>
                InterventionRequest.fromJson(item! as Map<String, Object?>),
          )
          .toList(),
    );
  }
}

class DemoSeed {
  const DemoSeed({
    required this.users,
    required this.artisans,
    required this.requests,
  });
  final List<AppUser> users;
  final List<Artisan> artisans;
  final List<InterventionRequest> requests;
}
