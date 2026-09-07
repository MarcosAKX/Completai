// Avaliação pública exibida no perfil do posto.
class StationReview {
  const StationReview({
    required this.clientUid,
    required this.clientName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String clientUid;
  final String clientName;
  final int rating;
  final String comment;
  final DateTime? createdAt;
}
