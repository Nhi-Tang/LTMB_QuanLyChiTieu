import 'package:flutter/material.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/savings_goal_model.dart';
import '../../backend/models/savings_transaction_model.dart';
import '../../core/utils/money_input_formatter.dart';
import '../utils/app_translations.dart';
import 'package:quanlychitieu/frontend/theme/app_colors.dart';
import 'app_alert_dialog.dart';
import '../utils/app_language.dart';

class AddEditSavingsGoalDialog extends StatefulWidget {
  final SavingsGoalModel? goalToEdit;
  final String selectedLanguage;
  final VoidCallback onSaved;

  const AddEditSavingsGoalDialog({
    super.key,
    this.goalToEdit,
    this.selectedLanguage = 'Tiếng Việt',
    required this.onSaved,
  });

  @override
  State<AddEditSavingsGoalDialog> createState() => _AddEditSavingsGoalDialogState();
}

class _AddEditSavingsGoalDialogState extends State<AddEditSavingsGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _initialController;
  final FocusNode _initialFocusNode = FocusNode();
  DateTime? _selectedDeadline;
  String _selectedIcon = 'assets/icon/tietkiem_icon.jpg';
  String _selectedColor = '0xFF2E7D32';

  final List<String> _availableIcons = [
    'assets/icon/tietkiem_icon.jpg',
    'assets/icon/laptop_icon.jpg',
    'assets/icon/maybay_icon.jpg',
    'assets/icon/baohiem_tk_icon.jpg',
    'assets/icon/xe_icon.jpg',
    'assets/icon/kethon_icon.jpg',
    'assets/icon/qua_icon.jpg',
    'assets/icon/nha_icon.jpg',
    'assets/icon/sach_icon.jpg',
    'assets/icon/concai_icon.jpg',
    'assets/icon/dienthoai_icon.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goalToEdit?.name ?? '');
    _targetController = TextEditingController(
      text: widget.goalToEdit != null ? formatMoney(widget.goalToEdit!.targetAmount) : '',
    );
    _initialController = TextEditingController(
      text: widget.goalToEdit != null ? formatMoney(widget.goalToEdit!.currentAmount) : '0',
    );
    _initialFocusNode.addListener(() {
      if (_initialFocusNode.hasFocus) {
        _initialController.selection = TextSelection(baseOffset: 0, extentOffset: _initialController.text.length);
      }
    });

    if (widget.goalToEdit?.deadline != null && widget.goalToEdit!.deadline!.isNotEmpty) {
      _selectedDeadline = DateTime.tryParse(widget.goalToEdit!.deadline!);
    }
    if (widget.goalToEdit != null) {
      _selectedIcon = widget.goalToEdit!.icon;
      _selectedColor = widget.goalToEdit!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _initialController.dispose();
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final isEditing = widget.goalToEdit != null;
    const accentPurple = Color(0xFFD4CCE2);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/icon/tietkiem_icon.jpg',
              width: 26,
              height: 26,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEditing ? AppTranslations.tr(lang, 'edit_savings_goal') : AppTranslations.tr(lang, 'add_savings_goal'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppTranslations.tr(lang, 'goal_name'),
                    hintText: context.t('VD: Mua laptop, Du lịch Đà Lạt...'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập tên mục tiêu') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: InputDecoration(
                    labelText: AppTranslations.tr(lang, 'target_amount'),
                    hintText: 'VD: 20.000.000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return context.t('Vui lòng nhập số tiền cần đạt');
                    if (parseMoney(v) <= 0) return context.t('Số tiền phải lớn hơn 0');
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (!isEditing) ...[
                  TextFormField(
                    controller: _initialController,
                    focusNode: _initialFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [MoneyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: AppTranslations.tr(lang, 'initial_amount'),
                      hintText: 'VD: 2.000.000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final val = parseMoney(v);
                        final targetVal = parseMoney(_targetController.text);
                        if (val < 0) return context.t('Số tiền không được âm');
                        if (targetVal > 0 && val > targetVal) return context.t('Số tiền ban đầu không được vượt quá số tiền cần đạt');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                // Deadline Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 90)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2040),
                    );
                    if (picked != null && mounted) {
                      setState(() => _selectedDeadline = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDeadline == null
                                      ? AppTranslations.tr(lang, 'deadline_optional')
                                      : context.t('Hạn: {day}/{month}/{year}', {'day': _selectedDeadline!.day, 'month': _selectedDeadline!.month, 'year': _selectedDeadline!.year}),
                                  style: TextStyle(
                                    color: _selectedDeadline == null ? Colors.grey[600] : Colors.black87,
                                    fontWeight: _selectedDeadline != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(AppTranslations.tr(lang, 'choose_icon'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableIcons.map((iconPath) {
                    final isSelected = _selectedIcon == iconPath;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = iconPath),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? accentPurple.withValues(alpha: 0.4) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? accentPurple : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(iconPath, width: 32, height: 32, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppTranslations.tr(lang, 'cancel'), style: const TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentPurple,
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final name = _nameController.text.trim();
              final target = parseMoney(_targetController.text).toDouble();
              final initial = parseMoney(_initialController.text).toDouble();

              if (name.isEmpty) {
                showAppAlertDialog(context: context, title: context.t('Lỗi'), message: context.t('Vui lòng nhập tên mục tiêu!'), isSuccess: false);
                return;
              }
              if (target <= 0) {
                showAppAlertDialog(context: context, title: context.t('Lỗi'), message: context.t('Số tiền cần đạt phải lớn hơn 0!'), isSuccess: false);
                return;
              }
              if (initial < 0 || initial > target) {
                showAppAlertDialog(context: context, title: context.t('Lỗi'), message: context.t('Số tiền ban đầu phải từ 0 và không vượt quá số tiền cần đạt!'), isSuccess: false);
                return;
              }

              if (isEditing) {
                final updated = widget.goalToEdit!.copyWith(
                  name: name,
                  targetAmount: target,
                  deadline: _selectedDeadline?.toIso8601String(),
                  icon: _selectedIcon,
                  color: _selectedColor,
                );
                await DatabaseHelper.instance.updateSavingsGoal(updated);
              } else {
                final newGoal = SavingsGoalModel(
                  name: name,
                  targetAmount: target,
                  currentAmount: initial,
                  deadline: _selectedDeadline?.toIso8601String(),
                  icon: _selectedIcon,
                  color: _selectedColor,
                  isCompleted: false,
                  createdAt: DateTime.now().toIso8601String(),
                );
                final goalId = await DatabaseHelper.instance.insertSavingsGoal(newGoal);
                if (initial > 0) {
                  await DatabaseHelper.instance.addSavingsTransaction(
                    SavingsTransactionModel(
                      goalId: goalId,
                      amount: initial,
                      isDeposit: true,
                      note: AppLanguage.instance.t('Số tiền ban đầu'),
                      date: DateTime.now().toIso8601String(),
                    ),
                  );
                }
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              widget.onSaved();
            }
          },
          child: Text(isEditing ? AppTranslations.tr(lang, 'save') : AppTranslations.tr(lang, 'create_goal_btn'), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
