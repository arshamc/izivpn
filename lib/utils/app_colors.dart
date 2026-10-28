import 'package:flutter/material.dart';

class AppColors {
  // Legacy compatibility
  static const Color appBgColor = Color(0xFF0B0D12);
  static const Color appButtonColor = Color(0xFF0B0D12);

  // Atmospheric Palette
  static const Color skySlateTop = Color(0xFF8FA5B5);
  static const Color skySlateMid = Color(0xFFB8C9D4);
  static const Color pureFogBottom = Color(0xFFFFFFFF);
  static const Color obsidianFogBottom = Color(0xFF0B0D12);

  // Primary Obsidian Capsule
  static const Color obsidianBlack = Color(0xFF0B0D12);
  static const Color obsidianSurface = Color(0xFF161B24);

  // Brand Accents
  static const Color brandCoral = Color(0xFFFF5A4E);
  static const Color brandCoralGlow = Color(0x55FF5A4E);
  static const Color cyberCyan = Color(0xFF7CE8FF);
  static const Color cyberCyanGlow = Color(0x667CE8FF);

  // Status Colors
  static const Color statusGreen = Color(0xFF12B886);
  static const Color statusAmber = Color(0xFFF59F00);
  static const Color statusRed = Color(0xFFFA5252);

  // Frosted Glass Colors
  static const Color frostedCardLight = Color(0xD9FFFFFF); // 85% opacity
  static const Color frostedBorderLight = Color(0xFFE6ECF0);
  static const Color frostedCardDark = Color(0xCC161B24); // 80% opacity
  static const Color frostedBorderDark = Color(0xFF262F3D);

  // Typography
  static const Color textHeadingLight = Color(0xFF14181E);
  static const Color textHeadingDark = Color(0xFFFFFFFF);
  static const Color textSubtitleLight = Color(0xFF4A5562);
  static const Color textSubtitleDark = Color(0xFF94A3B8);
  static const Color textMutedLight = Color(0xFF6C7886);
  static const Color textMutedDark = Color(0xFF64748B);

  // Helpers based on brightness
  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? frostedCardDark : frostedCardLight;

  static Color cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? frostedBorderDark : frostedBorderLight;

  static Color headingText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textHeadingDark : textHeadingLight;

  static Color subtitleText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSubtitleDark : textSubtitleLight;

  static Color mutedText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textMutedDark : textMutedLight;
}
