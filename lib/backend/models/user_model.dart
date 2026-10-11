class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String role; // 'admin' or 'user'
  final bool isActive; // true = active, false = locked
  final String createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user',
    this.isActive = true,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: map['role'] as String? ?? 'user',
      isActive: (map['isActive'] as int? ?? 1) == 1,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toString(),
    );
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? role,
    bool? isActive,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
