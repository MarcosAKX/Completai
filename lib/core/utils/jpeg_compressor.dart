// Redimensiona e comprime uma imagem para JPEG dentro de um teto de bytes.
//
// `compressToJpeg` é Dart puro (pacote `image`), sem plugin nativo — testável
// sem binding. `compressToJpegInBackground` roda o mesmo trabalho num isolate
// (`compute`) para não travar a thread da UI numa foto grande; é a versão que
// o app usa. A foto do posto é guardada como base64 num documento Firestore
// separado (limite de 1 MiB por documento).
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../errors/exceptions.dart';

/// Teto padrão da foto do posto: ~500 KB deixa margem confortável para o
/// base64 (~4/3) e os demais campos caberem no documento de 1 MiB.
const int kStationCoverMaxBytes = 500 * 1024;

/// Maior lado da foto após redimensionar. Suficiente para tela cheia em
/// aparelhos comuns sem inflar o documento.
const int kStationCoverMaxDimension = 1080;

/// Decodifica [source], corrige orientação EXIF, reduz para no máximo
/// [maxDimension] no maior lado e comprime em JPEG até ficar abaixo de
/// [maxBytes], baixando a qualidade em passos.
///
/// Lança [ValidationException] quando os bytes não são uma imagem suportada
/// ou quando nem na qualidade mínima o resultado cabe no teto.
Uint8List compressToJpeg(
  Uint8List source, {
  int maxBytes = kStationCoverMaxBytes,
  int maxDimension = kStationCoverMaxDimension,
}) {
  final decoded = img.decodeImage(source);
  if (decoded == null) {
    throw const ValidationException(
      'Não foi possível ler a imagem. Escolha uma foto JPEG ou PNG.',
    );
  }

  final oriented = img.bakeOrientation(decoded);
  final resized = (oriented.width > maxDimension || oriented.height > maxDimension)
      ? img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? maxDimension : null,
          height: oriented.height > oriented.width ? maxDimension : null,
        )
      : oriented;

  for (final quality in const [85, 75, 65, 55, 45, 35]) {
    final encoded = img.encodeJpg(resized, quality: quality);
    if (encoded.length <= maxBytes) return encoded;
  }
  throw const ValidationException(
    'A imagem é muito detalhada para o limite. Tente uma foto menor.',
  );
}

/// Igual a [compressToJpeg], mas num isolate — não bloqueia a UI. Propaga a
/// mesma [ValidationException] quando a imagem não pode ser lida ou reduzida.
Future<Uint8List> compressToJpegInBackground(Uint8List source) =>
    compute(_compressEntryPoint, source);

Uint8List _compressEntryPoint(Uint8List source) => compressToJpeg(source);
