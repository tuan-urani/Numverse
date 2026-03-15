import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/ui/profile/components/profile_menu_card.dart';
import 'package:test/src/ui/profile/interactor/profile_state.dart';

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({
    required this.items,
    required this.onTapItem,
    super.key,
  });

  final List<ProfileMenuItem> items;
  final ValueChanged<ProfileMenuItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < items.length; index++) ...<Widget>[
          ProfileMenuCard(
            title: items[index].titleKey.tr,
            subtitle: items[index].subtitleKey.tr,
            icon: items[index].icon,
            onTap: () => onTapItem(items[index]),
          ),
          if (index != items.length - 1) 8.height,
        ],
      ],
    );
  }
}
