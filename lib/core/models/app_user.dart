enum UserRole { client, artisan, admin }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.client => 'Client',
    UserRole.artisan => 'Artisan',
    UserRole.admin => 'Administrateur',
  };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, Object?> json) => AppUser(
    id: json['id']! as String,
    name: json['name']! as String,
    email: json['email']! as String,
    role: UserRole.values.byName(json['role']! as String),
  );

  final String id;
  final String name;
  final String email;
  final UserRole role;

  AppUser copyWith({String? name}) =>
      AppUser(id: id, name: name ?? this.name, email: email, role: role);

  Map<String, Object> toJson() => {
    'name': name,
    'email': email,
    'role': role.name,
  };
}
