import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:test/src/utils/app_colors.dart';

class AppStyles {
  AppStyles._();

  static const String fontFamily = 'BeVietnamPro';
  static const String fontDisplayFamily = 'PlayfairDisplay';
  static const String fontNumberFamily = 'Cinzel';

  static TextStyle _body(
    double size,
    FontWeight weight,
    Color color,
    double height,
  ) => GoogleFonts.beVietnamPro(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static TextStyle _display(
    double size,
    FontWeight weight,
    Color color,
    double height,
  ) => GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: 0.3,
  );

  static TextStyle _number(
    double size,
    FontWeight weight,
    Color color,
    double height,
  ) => GoogleFonts.cinzel(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: 0.4,
  );

  static TextStyle h40({
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w700,
  }) => _display(40, fontWeight, color, 1.2);

  static TextStyle h1({
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w700,
  }) => _display(32, fontWeight, color, 1.2);

  static TextStyle h2({
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w700,
  }) => _display(28, fontWeight, color, 1.25);

  static TextStyle headlineLarge({
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w700,
  }) => _display(36, fontWeight, color, 1.2);

  static TextStyle titleLarge({
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w700,
  }) => _display(24, fontWeight, color, 1.25);

  static TextStyle h3({
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w600,
  }) => _display(20, fontWeight, color, 1.3);

  static TextStyle h4({
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w600,
  }) => _body(18, fontWeight, color, 1.35);

  static TextStyle h5({
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w500,
  }) => _body(16, fontWeight, color, 1.4);

  static TextStyle bodyLarge({
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w400,
  }) => _body(16, fontWeight, color, 1.45);

  static TextStyle bodyMedium({
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w400,
  }) => _body(14, fontWeight, color, 1.45);

  static TextStyle bodySmall({
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w400,
  }) => _body(12, fontWeight, color, 1.4);

  static TextStyle caption({
    Color color = AppColors.textMuted,
    FontWeight fontWeight = FontWeight.w400,
  }) => _body(11, fontWeight, color, 1.35);

  static TextStyle buttonLarge({
    Color color = AppColors.midnight,
    FontWeight fontWeight = FontWeight.w600,
  }) => _body(16, fontWeight, color, 1.3);

  static TextStyle buttonMedium({
    Color color = AppColors.midnight,
    FontWeight fontWeight = FontWeight.w600,
  }) => _body(14, fontWeight, color, 1.3);

  static TextStyle buttonSmall({
    Color color = AppColors.midnight,
    FontWeight fontWeight = FontWeight.w600,
  }) => _body(12, fontWeight, color, 1.25);

  static TextStyle numberLarge({
    Color color = AppColors.richGold,
    FontWeight fontWeight = FontWeight.w700,
  }) => _number(48, fontWeight, color, 1.1);

  static TextStyle numberMedium({
    Color color = AppColors.richGold,
    FontWeight fontWeight = FontWeight.w700,
  }) => _number(32, fontWeight, color, 1.1);

  static TextStyle numberSmall({
    Color color = AppColors.richGold,
    FontWeight fontWeight = FontWeight.w700,
  }) => _number(24, fontWeight, color, 1.1);
}
