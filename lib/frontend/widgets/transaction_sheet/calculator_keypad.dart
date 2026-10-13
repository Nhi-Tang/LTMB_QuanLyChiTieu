import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mousey_colors.dart';

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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hôm nay';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    void handlePress(String key) {
      HapticFeedback.lightImpact();
      onKeyPressed(key);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: MouseyColors.keypadBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MouseyColors.borderBeige),
      ),
      child: Column(
        children: [
          // Row 1
          Row(
            children: [
              _buildKey('1', onTap: () => handlePress('1')),
              _buildKey('2', onTap: () => handlePress('2')),
              _buildKey('3', onTap: () => handlePress('3')),
              _buildKey('+', onTap: () => handlePress('+'), isOperator: true),
              const SizedBox(width: 6),
              _buildFunctionButton(
                icon: Icons.calendar_today_rounded,
                label: _formatDate(selectedDate),
                onTap: onDatePressed,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2
          Row(
            children: [
              _buildKey('4', onTap: () => handlePress('4')),
              _buildKey('5', onTap: () => handlePress('5')),
              _buildKey('6', onTap: () => handlePress('6')),
              _buildKey('-', onTap: () => handlePress('-'), isOperator: true),
              const SizedBox(width: 6),
              _buildFunctionButton(
                icon: Icons.edit_note,
                label: hasNote ? 'Sửa ghi chú' : 'Ghi chú',
                isHighlight: hasNote,
                onTap: onNotePressed,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 3
          Row(
            children: [
              _buildKey('7', onTap: () => handlePress('7')),
              _buildKey('8', onTap: () => handlePress('8')),
              _buildKey('9', onTap: () => handlePress('9')),
              _buildKey('×', onTap: () => handlePress('×'), isOperator: true),
              const SizedBox(width: 6),
              _buildIconFunctionButton(
                icon: Icons.backspace_outlined,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onDeletePressed();
                },
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  onDeleteLongPress();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 4
          Row(
            children: [
              _buildKey('.', onTap: () => handlePress('.')),
              _buildKey('0', onTap: () => handlePress('0')),
              _buildKey('000', onTap: () => handlePress('000')),
              _buildKey('÷', onTap: () => handlePress('÷'), isOperator: true),
              const SizedBox(width: 6),
              _buildSaveButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String label, {required VoidCallback onTap, bool isOperator = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: isOperator ? MouseyColors.keypadOperator : MouseyColors.keypadKey,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isOperator ? MouseyColors.textMain : MouseyColors.textMain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: isHighlight ? MouseyColors.selectedCream : MouseyColors.keypadOperator,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: MouseyColors.textMain),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: MouseyColors.textMain,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconFunctionButton({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: MouseyColors.keypadOperator,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: MouseyColors.textMain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MouseyColors.primaryGreen,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          onPressed: () {
            HapticFeedback.heavyImpact();
            onSavePressed();
          },
          child: const Text(
            'LƯU',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
