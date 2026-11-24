/// Hồ sơ người dùng lưu trên máy (app không còn đăng nhập/đăng ký)
class UserModel {
  final int? id;
  final String? uid;
  final String name;
  final String? photoUrl;
  final String createdAt;

  UserModel({
    this.id,
    this.uid,
    required this.name,
    this.photoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uid': uid,
      'name': name,
      // Cột email/password của bảng users là NOT NULL (email UNIQUE) từ bản có đăng nhập
      'email': uid ?? '',
      'password': '',
      'photoUrl': photoUrl,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      uid: map['uid'] as String?,
      name: map['name'] as String? ?? 'User',
      photoUrl: map['photoUrl'] as String?,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  UserModel copyWith({
    int? id,
    String? uid,
    String? name,
    String? photoUrl,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
