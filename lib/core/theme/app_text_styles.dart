// Roboto sugerida: fonte nativa Android, sem download em runtime.
import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const title = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const body = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    height: 1.5,
  );
  static const label = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const caption = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    height: 1.4,
  );
  static const textTheme = TextTheme(
    titleLarge: title,
    bodyLarge: body,
    bodyMedium: body,
    labelLarge: label,
    bodySmall: caption,
  );
}
