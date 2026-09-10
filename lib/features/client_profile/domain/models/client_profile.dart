// Dados privados do motorista, independentes de Firebase e widgets.
class ClientProfile {
  const ClientProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
  });
  final String uid;
  final String name;
  final String email;
  final String phone;
}
