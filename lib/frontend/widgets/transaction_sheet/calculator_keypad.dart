import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_language.dart';
import '../../theme/app_colors.dart';

/// Bàn phím nhập tiền kiểu sổ: 3 cột số, cột phải là Ngày, Ghi chú và nút Lưu cao gấp đôi
class CalculatorKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onDeleteLongPress;
  final VoidCallback onSavePressed;
  final VoidCallback onDatePressed;
  final VoidCallback onNotePressed;
  final DateTime selectedDate;
  final bool hasNote;

  const CalculatorKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onDeletePressed,
    required this.onDeleteLongPress,
    required this.onSavePressed,
    required this.onDatePressed,
    required this.onNotePressed,
    required this.selectedDate,
    required this.hasNote,
  });

  static const double _keyHeight = 52;
  static const double _gap = 8;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return AppLanguage.instance.t('Hôm nay');
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    void handlePress(String key) {
      HapticFeedback.lightImpact();
      onKeyPressed(key);
    }

    Widget digitRow(List<String> keys) => Row(
          children: [
            for (var i = 0; i < keys.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(child: _buildKey(keys[i], onTap: () => handlePress(keys[i]))),
            ],
          ],
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 cột số
        Expanded(
          flex: 3,
          child: Column(
            children: [
              digitRow(['1', '2', '3']),
              const SizedBox(height: _gap),
              digitRow(['4', '5', '6']),
              const SizedBox(height: _gap),
              digitRow(['7', '8', '9']),
              const SizedBox(height: _gap),
              Row(
                children: [
                  Expanded(child: _buildKey('000', onTap: () => handlePress('000'))),
                  const SizedBox(width: _gap),
                  Expanded(child: _buildKey('0', onTap: () => handlePress('0'))),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: _buildKey(
                      '',
                      icon: Icons.backspace_outlined,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onDeletePressed();
                      },
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        onDeleteLongPress();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: _gap),
        // Cột chức năng
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildSideButton(label: _formatDate(selectedDate), onTap: onDatePressed),
              const SizedBox(height: _gap),
              _buildSideButton(
                label: hasNote ? context.t('Sửa ghi chú') : context.t('Ghi chú'),
                onTap: onNotePressed,
              ),
              const SizedBox(height: _gap),
              _buildSaveButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String label, {required VoidCallback onTap, VoidCallback? onLongPress, IconData? icon}) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.rule),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: _keyHeight,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 22, color: AppColors.ink)
                : Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.ink)),
          ),
        ),
      ),
    );
  }

  Widget _buildSideButton({required String label, required VoidCallback onTap}) {
    return Material(
      color: AppColors.tealMist,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: _keyHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.mediumImpact();
          onSavePressed();
        },
        child: SizedBox(
          height: _keyHeight * 2 + _gap,
          child: Center(
            child: Text(
              context.t('Lưu'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.onTeal),
            ),
          ),
        ),
      ),
    );
  }
}
