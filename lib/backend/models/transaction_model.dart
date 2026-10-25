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
  final String? ledgerId;
  final String kind; // 'income', 'received', 'expense', 'transfer_out', 'transfer_internal'
  final String? transferGroupId;

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
    this.ledgerId,
    String? kind,
    this.transferGroupId,
  }) : kind = kind ?? (isExpense ? (category.toLowerCase().contains('chuyển tiền') ? 'transfer_out' : 'expense') : 'income'),
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

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
      'ledgerId': ledgerId ?? 'Sổ cá nhân 1',
      'kind': kind,
      'transferGroupId': transferGroupId,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    final isExp = (map['is_expense'] as int? ?? 1) == 1;
    final cat = map['category'] as String? ?? 'Khác';
    String defaultKind;
    if (isExp) {
      if (cat.toLowerCase().contains('chuyển tiền')) {
        defaultKind = 'transfer_out';
      } else {
        defaultKind = 'expense';
      }
    } else {
      defaultKind = 'income';
    }

    return TransactionItem(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] as String? ?? '',
      category: cat,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isExpense: isExp,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
      uid: map['uid'] as String?,
      ledgerId: map['ledgerId'] as String? ?? 'Sổ cá nhân 1',
      kind: map['kind'] as String? ?? defaultKind,
      transferGroupId: map['transferGroupId'] as String?,
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
    String? ledgerId,
    String? kind,
    String? transferGroupId,
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
      ledgerId: ledgerId ?? this.ledgerId,
      kind: kind ?? this.kind,
      transferGroupId: transferGroupId ?? this.transferGroupId,
    );
  }
}
