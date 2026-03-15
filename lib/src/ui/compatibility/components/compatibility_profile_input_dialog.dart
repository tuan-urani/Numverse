import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class CompatibilityProfileInputDialog extends StatefulWidget {
  const CompatibilityProfileInputDialog({required this.onSubmit, super.key});

  final Future<void> Function(String name, DateTime birthDate) onSubmit;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(String name, DateTime birthDate) onSubmit,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CompatibilityProfileInputDialog(onSubmit: onSubmit);
      },
    );
  }

  @override
  State<CompatibilityProfileInputDialog> createState() =>
      _CompatibilityProfileInputDialogState();
}

class _CompatibilityProfileInputDialogState
    extends State<CompatibilityProfileInputDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _dayController;
  late final TextEditingController _monthController;
  late final TextEditingController _yearController;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dayController = TextEditingController();
    _monthController = TextEditingController();
    _yearController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.mysticalCardGradient(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.35)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.richGold.withValues(alpha: 0.24),
              blurRadius: 24,
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
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: AppColors.richGold,
                  ),
                  8.width,
                  Expanded(
                    child: Text(
                      LocaleKey.compatibilityUnlockTitle.tr,
                      style: AppStyles.h3(fontWeight: FontWeight.w700),
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
              8.height,
              Text(
                LocaleKey.compatibilityUnlockSubtitle.tr,
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
              ),
              14.height,
              _FieldLabel(text: LocaleKey.profileNameLabel.tr),
              6.height,
              _InputContainer(
                child: TextField(
                  controller: _nameController,
                  style: AppStyles.bodyMedium(),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: LocaleKey.compatibilityAddDialogNameHint.tr,
                    hintStyle: AppStyles.bodySmall(color: AppColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              12.height,
              _FieldLabel(text: LocaleKey.profileBirthDateLabel.tr),
              6.height,
              Row(
                children: <Widget>[
                  Expanded(
                    child: _InputContainer(
                      child: TextField(
                        controller: _dayController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyMedium(),
                        decoration: InputDecoration(
                          hintText: 'DD',
                          hintStyle: AppStyles.bodySmall(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  8.width,
                  Expanded(
                    child: _InputContainer(
                      child: TextField(
                        controller: _monthController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyMedium(),
                        decoration: InputDecoration(
                          hintText: 'MM',
                          hintStyle: AppStyles.bodySmall(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  8.width,
                  Expanded(
                    child: _InputContainer(
                      child: TextField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyMedium(),
                        decoration: InputDecoration(
                          hintText: 'YYYY',
                          hintStyle: AppStyles.bodySmall(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              8.height,
              Text(
                LocaleKey.compatibilityUnlockDateHint.tr,
                style: AppStyles.caption(color: AppColors.textMuted),
              ),
              if (_errorText != null) ...<Widget>[
                8.height,
                Text(
                  _errorText!,
                  style: AppStyles.caption(color: AppColors.error),
                ),
              ],
              16.height,
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.transparent,
                    shadowColor: AppColors.transparent,
                    foregroundColor: AppColors.midnight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.midnight,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(Icons.auto_awesome, size: 16),
                            8.width,
                            Text(
                              LocaleKey.compatibilityUnlockAction.tr,
                              style: AppStyles.buttonMedium(),
                            ),
                          ],
                        ),
                ),
              ),
              12.height,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.26),
                  ),
                ),
                child: Text(
                  LocaleKey.compatibilityUnlockNote.tr,
                  style: AppStyles.caption(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final String name = _nameController.text.trim();
    final int? day = int.tryParse(_dayController.text.trim());
    final int? month = int.tryParse(_monthController.text.trim());
    final int? year = int.tryParse(_yearController.text.trim());

    if (name.isEmpty || day == null || month == null || year == null) {
      setState(() {
        _errorText = LocaleKey.compatibilityUnlockInvalid.tr;
      });
      return;
    }

    final DateTime? birthDate = _safeDate(year, month, day);
    if (birthDate == null || birthDate.isAfter(DateTime.now())) {
      setState(() {
        _errorText = LocaleKey.compatibilityUnlockInvalid.tr;
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    await widget.onSubmit(name, birthDate);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  DateTime? _safeDate(int year, int month, int day) {
    if (year < 1900 || year > DateTime.now().year) {
      return null;
    }

    final DateTime value = DateTime(year, month, day);
    final bool valid =
        value.year == year && value.month == month && value.day == day;
    return valid ? value : null;
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppStyles.bodySmall(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
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
