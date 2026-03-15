import 'package:flutter/material.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class ReadingProfileDialog extends StatefulWidget {
  const ReadingProfileDialog({required this.onSubmit, super.key});

  final Future<void> Function(String name, DateTime birthDate) onSubmit;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(String name, DateTime birthDate) onSubmit,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return ReadingProfileDialog(onSubmit: onSubmit);
      },
    );
  }

  @override
  State<ReadingProfileDialog> createState() => _ReadingProfileDialogState();
}

class _ReadingProfileDialogState extends State<ReadingProfileDialog> {
  late final TextEditingController _nameController;
  DateTime? _birthDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String dateLabel = _birthDate == null
        ? 'DD/MM/YYYY'
        : '${_birthDate!.day.toString().padLeft(2, '0')}/'
              '${_birthDate!.month.toString().padLeft(2, '0')}/'
              '${_birthDate!.year}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: AppColors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.mysticalCardGradient(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.richGold.withValues(alpha: 0.2),
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
              Text(
                'Thêm hồ sơ cá nhân',
                style: AppStyles.h3(fontWeight: FontWeight.w700),
              ),
              8.height,
              Text(
                'Nhập tên và ngày sinh để mở khóa toàn bộ luận giải.',
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
              ),
              14.height,
              _FieldLabel(text: 'Họ và tên'),
              6.height,
              _InputContainer(
                child: TextField(
                  controller: _nameController,
                  style: AppStyles.bodyMedium(),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Nguyen Van A',
                    hintStyle: AppStyles.bodySmall(color: AppColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              12.height,
              _FieldLabel(text: 'Ngày sinh'),
              6.height,
              InkWell(
                onTap: _isSubmitting ? null : _pickBirthDate,
                borderRadius: BorderRadius.circular(12),
                child: _InputContainer(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: AppStyles.bodyMedium(
                            color: _birthDate == null
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.richGold,
                      ),
                    ],
                  ),
                ),
              ),
              18.height,
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.8),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Hủy',
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
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shadowColor: AppColors.transparent,
                          backgroundColor: AppColors.transparent,
                          foregroundColor: AppColors.midnight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                            : Text(
                                'Lưu hồ sơ',
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
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.richGold,
              onPrimary: AppColors.midnight,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
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
    });
  }

  Future<void> _submit() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty || _birthDate == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await widget.onSubmit(name, _birthDate!);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
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
        color: AppColors.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: child,
      ),
    );
  }
}
