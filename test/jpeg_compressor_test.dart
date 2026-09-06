// Compressão da foto do posto: cabe no teto e continua decodificável.
import 'dart:typed_data';

import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/core/utils/jpeg_compressor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('imagem grande é reduzida e cabe no teto', () {
    final source = img.Image(width: 4000, height: 3000);
    // Ruído para o JPEG não comprimir "de graça" a ponto de mascarar o teste.
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgb(x, y, (x * 7) % 256, (y * 13) % 256, (x + y) % 256);
      }
    }
    final raw = img.encodePng(source);

    final compressed = compressToJpeg(raw, maxBytes: 200 * 1024);

    expect(compressed.length, lessThanOrEqualTo(200 * 1024));
    final decoded = img.decodeJpg(compressed);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(kStationCoverMaxDimension));
    expect(decoded.height, lessThanOrEqualTo(kStationCoverMaxDimension));
  });

  test('bytes inválidos viram ValidationException', () {
    expect(
      () => compressToJpeg(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<ValidationException>()),
    );
  });
}
