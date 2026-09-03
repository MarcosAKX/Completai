// Representa a sessão sem expor tipos Firebase às camadas superiores.
enum AccountRole { client, gasStation }

class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    this.role,
    this.isAdmin = false,
  });

  final String uid;
  final String email;
  final AccountRole? role;
  final bool isAdmin;
  bool get needsProfile => role == null;
}
