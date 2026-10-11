import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/db_helper.dart';
import '../models/savings_goal_model.dart';
import '../models/savings_transaction_model.dart';

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
  DateTime? _selectedDeadline;
  String _selectedIcon = '💻';
  String _selectedColor = '0xFF2E7D32';

  final List<String> _availableIcons = ['💻', '✈️', '🛡️', '🚗', '💍', '🎁', '🏠', '📚', '👶', '📱'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goalToEdit?.name ?? '');
    _targetController = TextEditingController(
      text: widget.goalToEdit != null ? widget.goalToEdit!.targetAmount.toStringAsFixed(0) : '',
    );
    _initialController = TextEditingController(
      text: widget.goalToEdit != null ? widget.goalToEdit!.currentAmount.toStringAsFixed(0) : '0',
    );
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
          const Icon(Icons.savings_rounded, color: accentBeige, size: 28),
          const SizedBox(width: 8),
          Text(
            isEditing ? 'Sửa mục tiêu tiết kiệm' : 'Thêm mục tiêu tiết kiệm',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: InputDecoration(
                  labelText: 'Số tiền cần đạt (đ)',
                  hintText: 'VD: 20000000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền cần đạt';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Số tiền không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (!isEditing) ...[
                TextFormField(
                  controller: _initialController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: InputDecoration(
                    labelText: 'Số tiền đã có sẵn ban đầu (đ)',
                    hintText: 'VD: 2000000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDeadline == null
                                ? 'Hạn hoàn thành (Không bắt buộc)'
                                : 'Hạn: ${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}',
                            style: TextStyle(
                              color: _selectedDeadline == null ? Colors.grey[600] : Colors.black87,
                              fontWeight: _selectedDeadline != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
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
                spacing: 8,
                runSpacing: 8,
                children: _availableIcons.map((ic) {
                  final isSel = _selectedIcon == ic;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = ic),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSel ? accentBeige.withValues(alpha: 0.2) : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(color: isSel ? accentBeige : Colors.transparent, width: 2),
                      ),
                      child: Center(child: Text(ic, style: const TextStyle(fontSize: 20))),
                    ),
                  );
                }).toList(),
              ),
            ],
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
              final target = double.parse(_targetController.text.trim());
              final initial = double.tryParse(_initialController.text.trim()) ?? 0.0;

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
