enum UserRole {
  employee,
  admin,
}

class User {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final UserRole role;
  final DateTime createdAt;
  final List<String> workplaceIds; // List of workplace IDs where the user works
  final List<String> workplaceNames; // List of workplace names for display
  int totalPoints;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
    this.workplaceIds = const [],
    this.workplaceNames = const [],
    this.totalPoints = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'workplaceIds': workplaceIds,
      'workplaceNames': workplaceNames,
      'totalPoints': totalPoints,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.employee,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      workplaceIds: List<String>.from(json['workplaceIds'] ?? []),
      workplaceNames: List<String>.from(json['workplaceNames'] ?? []),
      totalPoints: json['totalPoints'] ?? 0,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    UserRole? role,
    DateTime? createdAt,
    List<String>? workplaceIds,
    List<String>? workplaceNames,
    int? totalPoints,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      workplaceIds: workplaceIds ?? this.workplaceIds,
      workplaceNames: workplaceNames ?? this.workplaceNames,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}
