class UserChangeModel {
  final int? id;
  final int userId;
  final String userEmail;
  final String changedField;
  final String oldValue;
  final String newValue;
  final String changedAt;

  UserChangeModel({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.changedField,
    required this.oldValue,
    required this.newValue,
    required this.changedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'changed_field': changedField,
      'old_value': oldValue,
      'new_value': newValue,
      'changed_at': changedAt,
    };
  }

  factory UserChangeModel.fromMap(Map<String, dynamic> map) {
    return UserChangeModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? 0,
      userEmail: map['user_email'] as String? ?? '',
      changedField: map['changed_field'] as String? ?? '',
      oldValue: map['old_value'] as String? ?? '',
      newValue: map['new_value'] as String? ?? '',
      changedAt: map['changed_at'] as String? ?? '',
    );
  }
}
