class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final bool isActive; // true = active, false = locked
  final String createdAt;

  // New Firebase / Social login fields
  final String? uid;
  final String? photoUrl;
  final String provider; // 'password', 'google.com', 'facebook.com'
  final String plan; // 'free', 'pro'
  final String? proExpiredAt;
  final String? lastLoginAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.isActive = true,
    required this.createdAt,
    this.uid,
    this.photoUrl,
    this.provider = 'password',
    this.plan = 'free',
    this.proExpiredAt,
    this.lastLoginAt,
  });

  bool get isPro => plan == 'pro';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password': password,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
      'uid': uid,
      'photoUrl': photoUrl,
      'provider': provider,
      'plan': plan,
      'proExpiredAt': proExpiredAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? map['displayName'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      isActive: (map['isActive'] as int? ?? 1) == 1,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toString(),
      uid: map['uid'] as String?,
      photoUrl: map['photoUrl'] as String?,
      provider: map['provider'] as String? ?? 'password',
      plan: map['plan'] as String? ?? 'free',
      proExpiredAt: map['proExpiredAt'] as String?,
      lastLoginAt: map['lastLoginAt'] as String?,
    );
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    bool? isActive,
    String? createdAt,
    String? uid,
    String? photoUrl,
    String? provider,
    String? plan,
    String? proExpiredAt,
    String? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      uid: uid ?? this.uid,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      plan: plan ?? this.plan,
      proExpiredAt: proExpiredAt ?? this.proExpiredAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
