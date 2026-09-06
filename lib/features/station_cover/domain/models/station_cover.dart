// Foto de exibição de um posto, já decodificada e pronta para `Image.memory`.
import 'dart:typed_data';

class StationCover {
  const StationCover(this.bytes);

  /// Bytes JPEG. Vêm de `station_covers/{uid}.image` (base64) no Firestore.
  final Uint8List bytes;
}
