// Gera a chave estável usada em consultas de cidade no Firestore.
String citySearchKey(String value) {
  const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  var normalized = value.trim().toLowerCase();
  for (var index = 0; index < accents.length; index++) {
    normalized = normalized.replaceAll(accents[index], plain[index]);
  }
  return normalized.replaceAll(RegExp(r'\s+'), ' ');
}
