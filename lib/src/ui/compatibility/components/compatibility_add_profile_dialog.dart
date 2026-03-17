import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class CompatibilityAddProfileResult {
  const CompatibilityAddProfileResult({
    required this.name,
    required this.relation,
    required this.birthDate,
  });

  final String name;
  final String relation;
  final DateTime birthDate;
}

class CompatibilityAddProfileDialog extends StatefulWidget {
  const CompatibilityAddProfileDialog({super.key});

  static Future<CompatibilityAddProfileResult?> show(BuildContext context) {
    return showDialog<CompatibilityAddProfileResult>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const CompatibilityAddProfileDialog();
      },
    );
  }

  @override
  State<CompatibilityAddProfileDialog> createState() =>
      _CompatibilityAddProfileDialogState();
}

class _CompatibilityAddProfileDialogState
    extends State<CompatibilityAddProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _birthDateController;
  DateTime? _birthDate;
  String? _relation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _birthDateController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_RelationOption> options = <_RelationOption>[
      _RelationOption(
        value: 'lover',
        label: LocaleKey.compatibilityRelationLover.tr,
      ),
      _RelationOption(
        value: 'spouse',
        label: LocaleKey.compatibilityRelationSpouse.tr,
      ),
      _RelationOption(
        value: 'friend',
        label: LocaleKey.compatibilityRelationFriend.tr,
      ),
      _RelationOption(
        value: 'coworker',
        label: LocaleKey.compatibilityRelationCoworker.tr,
      ),
      _RelationOption(
        value: 'mother',
        label: LocaleKey.compatibilityRelationMother.tr,
      ),
      _RelationOption(
        value: 'father',
        label: LocaleKey.compatibilityRelationFather.tr,
      ),
      _RelationOption(
        value: 'sibling',
        label: LocaleKey.compatibilityRelationSibling.tr,
      ),
      _RelationOption(
        value: 'other',
        label: LocaleKey.compatibilityRelationOther.tr,
      ),
    ];

    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.mysticalCardGradient(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.32)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.richGold.withValues(alpha: 0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      LocaleKey.compatibilityAddDialogTitle.tr,
                      style: AppStyles.numberSmall(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ).copyWith(fontSize: 24, height: 1.2),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              14.height,
              _FieldLabel(
                text: LocaleKey.compatibilityAddDialogNameLabel.tr,
                icon: Icons.person_outline_rounded,
              ),
              6.height,
              _DialogInputField(
                controller: _nameController,
                hintText: LocaleKey.compatibilityAddDialogNameHint.tr,
              ),
              12.height,
              _FieldLabel(
                text: LocaleKey.compatibilityAddDialogRelationLabel.tr,
                icon: Icons.favorite_border_rounded,
              ),
              6.height,
              _InputContainer(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: _relation,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.richGold,
                    ),
                    hint: Text(
                      LocaleKey.compatibilityAddDialogRelationPlaceholder.tr,
                      style: AppStyles.bodySmall(color: AppColors.textMuted),
                    ),
                    dropdownColor: AppColors.midnightSoft,
                    borderRadius: BorderRadius.circular(12),
                    style: AppStyles.bodyMedium(),
                    items: options.map((_RelationOption item) {
                      return DropdownMenuItem<String>(
                        value: item.value,
                        child: Text(item.label),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _relation = value;
                      });
                    },
                  ),
                ),
              ),
              12.height,
              _FieldLabel(
                text: LocaleKey.compatibilityAddDialogBirthDateLabel.tr,
                icon: Icons.calendar_today_rounded,
              ),
              6.height,
              _DialogInputField(
                controller: _birthDateController,
                hintText:
                    LocaleKey.compatibilityAddDialogBirthDatePlaceholder.tr,
                readOnly: true,
                onTap: _pickBirthDate,
                suffixIcon: Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                ),
              ),
              18.height,
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.9),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        LocaleKey.commonCancel.tr,
                        style: AppStyles.buttonMedium(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.transparent,
                          shadowColor: AppColors.transparent,
                          foregroundColor: AppColors.midnight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          LocaleKey.compatibilityAddDialogAction.tr,
                          style: AppStyles.buttonMedium(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        _birthDate ?? DateTime(now.year - 20, now.month, now.day);
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.richGold,
              onPrimary: AppColors.midnight,
              surface: AppColors.midnightSoft,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.midnightSoft,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _birthDate = selected;
      _birthDateController.text = _formatBirthDate(selected);
    });
  }

  String _formatBirthDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _submit() {
    final String name = _nameController.text.trim();
    if (name.isEmpty || _relation == null || _birthDate == null) {
      return;
    }

    Navigator.of(context).pop(
      CompatibilityAddProfileResult(
        name: name,
        relation: _relation!,
        birthDate: _birthDate!,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.richGold),
        6.width,
        Text(
          text,
          style: AppStyles.bodySmall(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InputContainer extends StatelessWidget {
  const _InputContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: child,
      ),
    );
  }
}

class _DialogInputField extends StatelessWidget {
  const _DialogInputField({
    required this.controller,
    required this.hintText,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      showCursor: !readOnly,
      style: AppStyles.bodyMedium(),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppStyles.bodyMedium(color: AppColors.textMuted),
        suffixIcon: suffixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              ),
        suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        filled: true,
        fillColor: AppColors.deepViolet.withValues(alpha: 0.48),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.7),
            width: 1.1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.7),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.richGold, width: 1.4),
        ),
      ),
    );
  }
}

class _RelationOption {
  const _RelationOption({required this.value, required this.label});

  final String value;
  final String label;
}
