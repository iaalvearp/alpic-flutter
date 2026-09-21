class AuthUser {
  const AuthUser({required this.id, required this.email, required this.role});

  final String id;
  final String email;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    role: json['role'] as String? ?? 'USER',
  );
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    this.expiresAt,
  });

  final AuthUser user;
  final String accessToken;
  final int? expiresAt;
}
