class BudgetModel {
  final String? id;
  final String? uid;
  final String? categoryId; // Null = tổng ngân sách tháng
  final double amountLimit;
  final String? month; // Định dạng 'YYYY-MM', null nếu áp dụng mọi tháng hoặc định kỳ
  final bool isRecurring;
  final String? ledgerId;
  final int updatedAt;
  final bool isDeleted;
  final bool isSynced;

  BudgetModel({
    this.id,
    this.uid,
    this.categoryId,
    required this.amountLimit,
    this.month,
    this.isRecurring = false,
    this.ledgerId,
    int? updatedAt,
    this.isDeleted = false,
    this.isSynced = false,
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uid': uid,
      'categoryId': categoryId,
      'amountLimit': amountLimit.toInt(),
      'month': month,
      'isRecurring': isRecurring ? 1 : 0,
      'ledgerId': ledgerId,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id']?.toString(),
      uid: map['uid'] as String?,
      categoryId: map['categoryId'] as String?,
      amountLimit: (map['amountLimit'] as num?)?.toDouble() ?? 0.0,
      month: map['month'] as String?,
      isRecurring: (map['isRecurring'] as int? ?? 0) == 1,
      ledgerId: map['ledgerId'] as String?,
      updatedAt: map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
    );
  }

  BudgetModel copyWith({
    String? id,
    String? uid,
    String? categoryId,
    double? amountLimit,
    String? month,
    bool? isRecurring,
    String? ledgerId,
    int? updatedAt,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      categoryId: categoryId ?? this.categoryId,
      amountLimit: amountLimit ?? this.amountLimit,
      month: month ?? this.month,
      isRecurring: isRecurring ?? this.isRecurring,
      ledgerId: ledgerId ?? this.ledgerId,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
