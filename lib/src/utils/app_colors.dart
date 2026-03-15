import 'package:flutter/material.dart';

import 'package:test/src/extensions/color_extension.dart';

class AppColors {
  AppColors._();

  static const Color midnight = Color(0xFF0A0318);
  static const Color midnightSoft = Color(0xFF0F0620);
  static const Color deepViolet = Color(0xFF1E1438);
  static const Color violetAccent = Color(0xFF2A1F4A);

  static const Color richGold = Color(0xFFD4AF37);
  static const Color goldBright = Color(0xFFF4D03F);
  static const Color goldSoft = Color(0xFFE8C578);

  static const Color textPrimary = Color(0xFFF5F3ED);
  static const Color textSecondary = Color(0xFFE8D7B8);
  static const Color textMuted = Color(0xFF8B7F99);

  static const Color success = Color(0xFF61B15A);
  static const Color warning = Color(0xFFE8B44D);
  static const Color error = Color(0xFFC74444);
  static const Color energyRed = Color(0xFFEF4444);
  static const Color energyOrange = Color(0xFFF97316);
  static const Color energyYellow = Color(0xFFEAB308);
  static const Color energyAmber = Color(0xFFF59E0B);
  static const Color energyGreen = Color(0xFF22C55E);
  static const Color energyEmerald = Color(0xFF10B981);
  static const Color energyBlue = Color(0xFF3B82F6);
  static const Color energyCyan = Color(0xFF06B6D4);
  static const Color energyPurple = Color(0xFFA855F7);
  static const Color energyPink = Color(0xFFEC4899);
  static const Color energyRose = Color(0xFFF43F5E);
  static const Color energyIndigo = Color(0xFF6366F1);
  static const Color energyViolet = Color(0xFF8B5CF6);
  static const Color energyTeal = Color(0xFF14B8A6);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  static const Color background = midnight;
  static const Color card = midnightSoft;
  static const Color border = Color(0xFF2A1F4A);
  static const Color colorF8F1DD = Color(0xFFF8F1DD);
  static const Color colorF1D2BC = Color(0xFFF1D2BC);

  // Legacy aliases kept for compatibility with existing shared widgets.
  static const Color primary = richGold;
  static const Color primaryLight = goldBright;
  static const Color primaryAlpha10 = Color(0x1AD4AF37);
  static const Color secondary1 = deepViolet;
  static const Color secondary2 = violetAccent;
  static const Color textDisabled = textMuted;
  static const Color textInverse = midnight;
  static const Color backgroundSecondary = midnightSoft;
  static const Color backgroundDisabled = deepViolet;
  static const Color backgroundOverlay = Color(0xA6000000);
  static const Color borderLight = border;
  static const Color borderDark = deepViolet;

  static LinearGradient appBackgroundGradient() => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[midnight, midnight, deepViolet],
    stops: <double>[0, 0.7, 1],
  );

  static LinearGradient mysticalCardGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xEE0F0620), Color(0xCC1A1030)],
  );

  static LinearGradient goldTextGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[richGold, goldBright, richGold],
  );

  static LinearGradient primaryGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[richGold, goldBright],
  );

  static LinearGradient secondaryGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[deepViolet, violetAccent],
  );

  static LinearGradient primaryTextGradient() => goldTextGradient();

  static LinearGradient fadeGradient() => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[black.withOpacityX(0.2), black.withOpacityX(0.75)],
  );

  static LinearGradient disabledGradient() =>
      const LinearGradient(colors: <Color>[deepViolet, violetAccent]);

  static LinearGradient primaryBackgroundGradient() => appBackgroundGradient();

  static Color fromHex(String hex) {
    final StringBuffer buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) {
      buffer.write('ff');
    }
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
