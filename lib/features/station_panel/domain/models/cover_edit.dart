// Intenção do dono sobre a foto ao salvar a tela "Editar exibição".
enum CoverEditKind {
  /// Não mexer na foto atual.
  keep,

  /// Substituir pela imagem escolhida (bytes acompanham a chamada).
  replace,

  /// Apagar a foto atual.
  remove,
}
