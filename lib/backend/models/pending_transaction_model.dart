class PendingTransactionModel {
  final String id;
  final String? uid;
  final String type; // 'expense' hoặc 'income'
  final int amount; // Số tiền (VND)
  final String bankName; // Tên ngân hàng (e.g. Vietcombank, MB Bank)
  final String accountLast4; // 4 số cuối tài khoản
  final String description; // Mô tả tối đa 120 ký tự
  final String occurredAt; // Thời gian xảy ra giao dịch (ISO8601)
  final String fingerprint; // Fingerprint để chống trùng lặp
  final String status; // 'pending' | 'confirmed' | 'dismissed'
  final String? suggestedCategoryId; // Danh mục gợi ý (hoặc tên/ID danh mục)
  final String suggestionConfidence; // 'none' | 'medium' | 'high'
  final String createdAt; // Thời gian tạo bản ghi (ISO8601)

  PendingTransactionModel({
    required this.id,
    this.uid,
    required this.type,
    required this.amount,
    required this.bankName,
    this.accountLast4 = '',
    required this.description,
    required this.occurredAt,
    required this.fingerprint,
    this.status = 'pending',
    this.suggestedCategoryId,
    this.suggestionConfidence = 'none',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'type': type,
      'amount': amount,
      'bankName': bankName,
      'accountLast4': accountLast4,
      'description': description.length > 120 ? description.substring(0, 120) : description,
      'occurredAt': occurredAt,
      'fingerprint': fingerprint,
      'status': status,
      'suggestedCategoryId': suggestedCategoryId,
      'suggestionConfidence': suggestionConfidence,
      'createdAt': createdAt,
    };
  }

  factory PendingTransactionModel.fromMap(Map<String, dynamic> map) {
    return PendingTransactionModel(
      id: map['id'] as String? ?? '',
      uid: map['uid'] as String?,
      type: map['type'] as String? ?? 'expense',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      bankName: map['bankName'] as String? ?? 'Ngân hàng',
      accountLast4: map['accountLast4'] as String? ?? '',
      description: map['description'] as String? ?? '',
      occurredAt: map['occurredAt'] as String? ?? DateTime.now().toIso8601String(),
      fingerprint: map['fingerprint'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      suggestedCategoryId: map['suggestedCategoryId'] as String?,
      suggestionConfidence: map['suggestionConfidence'] as String? ?? 'none',
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  PendingTransactionModel copyWith({
    String? id,
    String? uid,
    String? type,
    int? amount,
    String? bankName,
    String? accountLast4,
    String? description,
    String? occurredAt,
    String? fingerprint,
    String? status,
    String? suggestedCategoryId,
    String? suggestionConfidence,
    String? createdAt,
  }) {
    return PendingTransactionModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      bankName: bankName ?? this.bankName,
      accountLast4: accountLast4 ?? this.accountLast4,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      fingerprint: fingerprint ?? this.fingerprint,
      status: status ?? this.status,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      suggestionConfidence: suggestionConfidence ?? this.suggestionConfidence,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
