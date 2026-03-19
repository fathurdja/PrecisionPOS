import 'package:flutter/material.dart';

/// Design system color tokens extracted from the Precision POS design.
/// Based on Material 3 surface hierarchy and "No-Line" philosophy.
class AppColors {
  AppColors._();

  // === Primary ===
  static const Color primary = Color(0xFF001E40);
  static const Color primaryContainer = Color(0xFF003366);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF799DD6);
  static const Color primaryFixed = Color(0xFFD5E3FF);
  static const Color primaryFixedDim = Color(0xFFA7C8FF);
  static const Color onPrimaryFixed = Color(0xFF001B3C);
  static const Color onPrimaryFixedVariant = Color(0xFF1F477B);
  static const Color inversePrimary = Color(0xFFA7C8FF);

  // === Secondary (Emerald / Growth) ===
  static const Color secondary = Color(0xFF006D36);
  static const Color secondaryContainer = Color(0xFF83FBA5);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF00743A);
  static const Color secondaryFixed = Color(0xFF83FBA5);
  static const Color secondaryFixedDim = Color(0xFF66DD8B);
  static const Color onSecondaryFixed = Color(0xFF00210C);
  static const Color onSecondaryFixedVariant = Color(0xFF005227);

  // === Tertiary ===
  static const Color tertiary = Color(0xFF381300);
  static const Color tertiaryContainer = Color(0xFF592300);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFD8885C);
  static const Color tertiaryFixed = Color(0xFFFFDBCA);
  static const Color tertiaryFixedDim = Color(0xFFFFB690);
  static const Color onTertiaryFixed = Color(0xFF341100);
  static const Color onTertiaryFixedVariant = Color(0xFF723610);

  // === Error ===
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // === Surface Hierarchy ===
  static const Color surface = Color(0xFFF9F9FE);
  static const Color surfaceBright = Color(0xFFF9F9FE);
  static const Color surfaceDim = Color(0xFFDAD9DE);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F3F8);
  static const Color surfaceContainer = Color(0xFFEEEDF2);
  static const Color surfaceContainerHigh = Color(0xFFE8E8ED);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E7);
  static const Color surfaceVariant = Color(0xFFE2E2E7);
  static const Color surfaceTint = Color(0xFF3A5F94);

  // === On Surface ===
  static const Color onSurface = Color(0xFF1A1C1F);
  static const Color onSurfaceVariant = Color(0xFF43474F);
  static const Color onBackground = Color(0xFF1A1C1F);
  static const Color background = Color(0xFFF9F9FE);

  // === Inverse ===
  static const Color inverseSurface = Color(0xFF2F3034);
  static const Color inverseOnSurface = Color(0xFFF1F0F5);

  // === Outline ===
  static const Color outline = Color(0xFF737780);
  static const Color outlineVariant = Color(0xFFC3C6D1);

  // === Custom / Navigation ===
  static const Color emeraldActive = Color(0xFF50C878);
}
