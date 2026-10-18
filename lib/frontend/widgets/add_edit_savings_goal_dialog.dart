import 'package:flutter/material.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/savings_goal_model.dart';
import '../../backend/models/savings_transaction_model.dart';
import '../../core/utils/money_input_formatter.dart';
import 'app_alert_dialog.dart';

class AddEditSavingsGoalDialog extends StatefulWidget {
  final SavingsGoalModel? goalToEdit;
  final VoidCallback onSaved;

  const AddEditSavingsGoalDialog({
    super.key,
    this.goalToEdit,
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
    final isEditing = widget.goalToEdit != null;
    const accentBeige = Color(0xFFE5D3AF);

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
              isEditing ? 'Sửa mục tiêu tiết kiệm' : 'Thêm mục tiêu tiết kiệm',
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
                    labelText: 'Tên mục tiêu',
                    hintText: 'VD: Mua laptop, Du lịch Đà Lạt...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên mục tiêu' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Số tiền cần đạt (đ)',
                    hintText: 'VD: 20.000.000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền cần đạt';
                    if (parseMoney(v) <= 0) return 'Số tiền phải lớn hơn 0';
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
                      labelText: 'Số tiền đã có sẵn ban đầu (đ)',
                      hintText: 'VD: 2.000.000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final val = parseMoney(v);
                        final targetVal = parseMoney(_targetController.text);
                        if (val < 0) return 'Số tiền không được âm';
                        if (targetVal > 0 && val > targetVal) return 'Số tiền ban đầu không được vượt quá số tiền cần đạt';
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
                    if (picked != null) {
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
                                      ? 'Hạn hoàn thành (Tùy chọn)'
                                      : 'Hạn: ${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}',
                                  style: TextStyle(
                                    color: _selectedDeadline == null ? Colors.grey[600] : Colors.black87,
                                    fontWeight: _selectedDeadline != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedDeadline != null)
                          InkWell(
                            onTap: () => setState(() => _selectedDeadline = null),
                            child: const Icon(Icons.clear, size: 18, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Chọn Icon:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableIcons.map((ic) {
                    final isSel = _selectedIcon == ic;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = ic),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? const Color(0xFFD4A55A) : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              ic,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.category_rounded,
                                size: 24,
                                color: Colors.grey,
                              ),
                            ),
                          ),
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
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentBeige,
            foregroundColor: const Color(0xFF5D4222),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final name = _nameController.text.trim();
              final target = parseMoney(_targetController.text).toDouble();
              final initial = parseMoney(_initialController.text).toDouble();

              if (name.isEmpty) {
                showAppAlertDialog(context: context, title: 'Lỗi', message: 'Vui lòng nhập tên mục tiêu!', isSuccess: false);
                return;
              }
              if (target <= 0) {
                showAppAlertDialog(context: context, title: 'Lỗi', message: 'Số tiền cần đạt phải lớn hơn 0!', isSuccess: false);
                return;
              }
              if (initial < 0 || initial > target) {
                showAppAlertDialog(context: context, title: 'Lỗi', message: 'Số tiền ban đầu phải từ 0 và không vượt quá số tiền cần đạt!', isSuccess: false);
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
                      note: 'Số tiền ban đầu',
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
          child: Text(isEditing ? 'LƯU' : 'TẠO MỤC TIÊU', style: const TextStyle(color: Color(0xFF5D4222), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
