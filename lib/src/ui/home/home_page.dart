import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../locale/locale_key.dart';
import '../../utils/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.transparent,
        surfaceTintColor: AppColors.transparent,
        title: Text(LocaleKey.homeTitle.tr),
      ),
      body: Center(child: Text(LocaleKey.homeTitle.tr)),
    );
  }
}
