import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class CompatibilityProfileInputDialog extends StatefulWidget {
  const CompatibilityProfileInputDialog({
    required this.onSubmit,
    this.title,
    this.subtitle,
    this.submitLabel,
    this.initialName,
    this.initialBirthDate,
    this.note,
    this.onBeforeSubmit,
    super.key,
  });

  final Future<void> Function(String name, DateTime birthDate) onSubmit;
  final Future<bool> Function(BuildContext context)? onBeforeSubmit;
  final String? title;
  final String? subtitle;
  final String? submitLabel;
  final String? initialName;
  final DateTime? initialBirthDate;
  final String? note;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(String name, DateTime birthDate) onSubmit,
    String? title,
    String? subtitle,
    String? submitLabel,
    String? initialName,
    DateTime? initialBirthDate,
    String? note,
    Future<bool> Function(BuildContext context)? onBeforeSubmit,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CompatibilityProfileInputDialog(
          onSubmit: onSubmit,
          title: title,
          subtitle: subtitle,
          submitLabel: submitLabel,
          initialName: initialName,
          initialBirthDate: initialBirthDate,
          note: note,
          onBeforeSubmit: onBeforeSubmit,
        );
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
  late final TextEditingController _birthDateController;
  DateTime? _birthDate;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _birthDateController = TextEditingController();
    _birthDate = widget.initialBirthDate;
    if (_birthDate != null) {
      _birthDateController.text = _formatBirthDate(_birthDate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String noteText = widget.note ?? LocaleKey.compatibilityUnlockNote.tr;
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
                      widget.title ?? LocaleKey.compatibilityUnlockTitle.tr,
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
                widget.subtitle ?? LocaleKey.compatibilityUnlockSubtitle.tr,
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
              ),
              14.height,
              _FieldLabel(text: LocaleKey.profileNameLabel.tr),
              6.height,
              _DialogInputField(
                controller: _nameController,
                hintText: LocaleKey.compatibilityAddDialogNameHint.tr,
                errorText: _errorText,
                onChanged: (_) {
                  if (_errorText == null) {
                    return;
                  }
                  setState(() {
                    _errorText = null;
                  });
                },
              ),
              12.height,
              _FieldLabel(text: LocaleKey.profileBirthDateLabel.tr),
              6.height,
              _DialogInputField(
                controller: _birthDateController,
                hintText:
                    LocaleKey.compatibilityAddDialogBirthDatePlaceholder.tr,
                readOnly: true,
                onTap: _pickBirthDate,
                errorText: _errorText,
                suffixIcon: Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                ),
              ),
              // 8.height,
              // Text(
              //   LocaleKey.compatibilityUnlockDateHint.tr,
              //   style: AppStyles.caption(color: AppColors.textMuted),
              // ),
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
                              widget.submitLabel ??
                                  LocaleKey.compatibilityUnlockAction.tr,
                              style: AppStyles.buttonMedium(),
                            ),
                          ],
                        ),
                ),
              ),
              if (noteText.isNotEmpty) ...<Widget>[
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
                    noteText,
                    style: AppStyles.caption(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty || _birthDate == null) {
      setState(() {
        _errorText = LocaleKey.compatibilityUnlockInvalid.tr;
      });
      return;
    }

    final DateTime birthDate = _birthDate!;
    if (birthDate.isAfter(DateTime.now())) {
      setState(() {
        _errorText = LocaleKey.compatibilityUnlockInvalid.tr;
      });
      return;
    }

    if (widget.onBeforeSubmit != null) {
      final bool canContinue = await widget.onBeforeSubmit!.call(context);
      if (!mounted || !canContinue) {
        return;
      }
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

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        _birthDate ?? DateTime(now.year - 20, now.month, now.day);
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
      _errorText = null;
    });
  }

  String _formatBirthDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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

class _DialogInputField extends StatelessWidget {
  const _DialogInputField({
    required this.controller,
    required this.hintText,
    this.errorText,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null;
    return TextField(
      controller: controller,
      onChanged: onChanged,
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
        errorText: hasError ? '' : null,
        errorStyle: const TextStyle(height: 0, fontSize: 0),
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
            color: hasError
                ? AppColors.error.withValues(alpha: 0.9)
                : AppColors.border.withValues(alpha: 0.7),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? AppColors.error : AppColors.richGold,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
