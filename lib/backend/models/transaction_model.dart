class TransactionItem {
  final String id;
  final String title;
  final String category;
  final double amount;
  final bool isExpense;
  final DateTime date;
  final int updatedAt;
  final bool isDeleted;
  final bool isSynced;
  final String? uid;

  TransactionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.isExpense,
    required this.date,
    int? updatedAt,
    this.isDeleted = false,
    this.isSynced = false,
    this.uid,
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'is_expense': isExpense ? 1 : 0,
      'date': date.toIso8601String(),
      'updatedAt': updatedAt,
      'isDeleted': isDeleted ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
      'uid': uid,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'Khác',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isExpense: (map['is_expense'] as int? ?? 1) == 1,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
      uid: map['uid'] as String?,
    );
  }

  TransactionItem copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    bool? isExpense,
    DateTime? date,
    int? updatedAt,
    bool? isDeleted,
    bool? isSynced,
    String? uid,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      isExpense: isExpense ?? this.isExpense,
      date: date ?? this.date,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
      uid: uid ?? this.uid,
    );
  }
}
