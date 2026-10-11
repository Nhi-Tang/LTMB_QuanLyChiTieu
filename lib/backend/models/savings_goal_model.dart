class SavingsGoalModel {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? deadline;
  final String icon;
  final String color;
  final bool isCompleted;
  final String createdAt;

  SavingsGoalModel({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.icon,
    required this.color,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline,
      'icon': icon,
      'color': color,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0.0,
      deadline: map['deadline'] as String?,
      icon: map['icon'] as String? ?? '🐖',
      color: map['color'] as String? ?? '0xFF2E7D32',
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  SavingsGoalModel copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? deadline,
    String? icon,
    String? color,
    bool? isCompleted,
    String? createdAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
