class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String role;
  final String? createdAt;

  const UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user',
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: map['role'] as String? ?? 'user',
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    if (id != null) map['id'] = id;
    if (createdAt != null) map['created_at'] = createdAt;
    return map;
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isAdmin => role == 'admin';
}
