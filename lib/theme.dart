import 'package:flutter/material.dart';

class ChachiColors {
  static const bg = Color(0xFFF6F9FC);
  static const panel = Color(0xFFFFFFFF);
  static const line = Color(0xFFE4EAF3);
  static const text = Color(0xFF1E2A3A);
  static const muted = Color(0xFF7C8AA0);
  static const accent = Color(0xFF2DD4BF);
  static const accent2 = Color(0xFF4FA3F7);
}

const List<Map<String, dynamic>> kColorSwatches = [
  {'name': 'آبی', 'value': 0xFF4FA3F7},
  {'name': 'صورتی', 'value': 0xFFFF6FA5},
  {'name': 'سبز', 'value': 0xFF34D399},
  {'name': 'کهربایی', 'value': 0xFFFBBF24},
  {'name': 'بنفش', 'value': 0xFFA78BFA},
  {'name': 'نارنجی', 'value': 0xFFFB923C},
  {'name': 'قرمز', 'value': 0xFFFB7185},
  {'name': 'فیروزه‌ای', 'value': 0xFF2DD4BF},
];

const List<String> kEmojiChoices = [
  '💧','🦷','🚶','🧘','👀','💊','🍎','😴','🧴','📵','☕','🌬️','📖','✍️','🩹','🧠'
];

ThemeData buildChachiTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: ChachiColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ChachiColors.accent,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ChachiColors.bg,
      elevation: 0,
      foregroundColor: ChachiColors.text,
    ),
  );
}
