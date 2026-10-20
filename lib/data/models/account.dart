enum UserRole { student, admin }

/// Аккаунт пользователя (коллекция `users` в Firestore).
/// Пока хранится на телефоне; пароль — только в виде хеша с солью.
class Account {
  const Account({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.passwordHash,
    this.salt,
    this.school,
    this.region,
    this.grade,
  });

  final String id;
  final String firstName;
  final String lastName;

  /// В нижнем регистре, без пробелов по краям.
  final String email;
  final UserRole role;
  final DateTime createdAt;

  /// `null` — аккаунт создан через Google, без пароля.
  final String? passwordHash;
  final String? salt;
  final String? school;

  /// Код региона, см. `Region`.
  final String? region;
  final int? grade;

  bool get isAdmin => role == UserRole.admin;
  String get fullName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

  Account copyWith({
    String? firstName,
    String? lastName,
    String? passwordHash,
    String? salt,
    String? school,
    String? region,
    int? grade,
  }) => Account(
    id: id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email,
    role: role,
    createdAt: createdAt,
    passwordHash: passwordHash ?? this.passwordHash,
    salt: salt ?? this.salt,
    school: school ?? this.school,
    region: region ?? this.region,
    grade: grade ?? this.grade,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'role': role.name,
    'createdAt': createdAt.toIso8601String(),
    'passwordHash': passwordHash,
    'salt': salt,
    'school': school,
    'region': region,
    'grade': grade,
  };

  factory Account.fromJson(Map<String, Object?> json) => Account(
    id: json['id'] as String,
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    email: json['email'] as String,
    role: json['role'] == UserRole.admin.name
        ? UserRole.admin
        : UserRole.student,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    passwordHash: json['passwordHash'] as String?,
    salt: json['salt'] as String?,
    school: json['school'] as String?,
    region: json['region'] as String?,
    grade: json['grade'] as int?,
  );
}
