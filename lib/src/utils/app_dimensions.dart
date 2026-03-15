import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppDimensions {
  AppDimensions._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  static const double pageHorizontal = 16;
  static const double pageVertical = 20;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;

  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double iconLarge = 24;
  static const double touchTarget = 44;

  static const double top = 16;
  static const double marginLeft = 16;
  static const double marginRight = 16;
  static const EdgeInsets sideMargins = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets allMargins = EdgeInsets.all(16);
  static const EdgeInsetsGeometry paddingTop = EdgeInsets.only(top: 280);

  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(radiusMd),
  );

  static double bottomBarHeight = 64 + Get.mediaQuery.padding.bottom;
  static const double iconPlusBottomBarHeight = 40;
  static double totalBottomBarHeight =
      bottomBarHeight + iconPlusBottomBarHeight;
}
