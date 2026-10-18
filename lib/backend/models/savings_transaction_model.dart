class SavingsTransactionModel {
  final int? id;
  final String goalId;
  final double amount;
  final bool isDeposit;
  final String? note;
  final String date;

  SavingsTransactionModel({
    this.id,
    required this.goalId,
    required this.amount,
    required this.isDeposit,
    this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'goal_id': goalId,
      'amount': amount,
      'is_deposit': isDeposit ? 1 : 0,
      'note': note,
      'date': date,
    };
  }

  factory SavingsTransactionModel.fromMap(Map<String, dynamic> map) {
    return SavingsTransactionModel(
      id: map['id'] as int?,
      goalId: map['goal_id']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isDeposit: (map['is_deposit'] as int? ?? 1) == 1,
      note: map['note'] as String?,
      date: map['date'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
