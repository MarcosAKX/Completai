// Representa a sessão sem expor tipos Firebase às camadas superiores.
enum AccountRole { client, gasStation }

class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    this.name,
    this.role,
    this.isAdmin = false,
  });

  final String uid;
  final String email;
  final String? name;
  final AccountRole? role;
  final bool isAdmin;

  bool get needsProfile => role == null;

  // Retorna somente o primeiro nome para uso na interface.
  String? get firstName {
    final value = name?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value.split(RegExp(r'\s+')).first;
  }
}
