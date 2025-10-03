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
  final List<String>
      companyIds; // List of company IDs the user is associated with
  final List<String> companyNames; // List of company names for display
  final String?
      primaryCompanyId; // For admins, this is their company; for employees, their main company
  int totalPoints; // Deprecated: kept for backward compatibility
  final Map<String, int>
      companyPoints; // Points per company: {companyId: points}

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
    this.workplaceIds = const [],
    this.workplaceNames = const [],
    this.companyIds = const [],
    this.companyNames = const [],
    this.primaryCompanyId,
    this.totalPoints = 0,
    this.companyPoints = const {},
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
      'companyIds': companyIds,
      'companyNames': companyNames,
      'primaryCompanyId': primaryCompanyId,
      'totalPoints': totalPoints,
      'companyPoints': companyPoints,
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
      companyIds: List<String>.from(json['companyIds'] ?? []),
      companyNames: List<String>.from(json['companyNames'] ?? []),
      primaryCompanyId: json['primaryCompanyId'],
      totalPoints: json['totalPoints'] ?? 0,
      companyPoints: json['companyPoints'] != null
          ? Map<String, int>.from(json['companyPoints'])
          : {},
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
    List<String>? companyIds,
    List<String>? companyNames,
    String? primaryCompanyId,
    int? totalPoints,
    Map<String, int>? companyPoints,
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
      companyIds: companyIds ?? this.companyIds,
      companyNames: companyNames ?? this.companyNames,
      primaryCompanyId: primaryCompanyId ?? this.primaryCompanyId,
      totalPoints: totalPoints ?? this.totalPoints,
      companyPoints: companyPoints ?? this.companyPoints,
    );
  }

  // Helper method to get points for a specific company
  int getCompanyPoints(String? companyId) {
    if (companyId == null) return totalPoints; // Fallback to global points
    return companyPoints[companyId] ?? 0;
  }

  // Helper method to set points for a specific company
  User setCompanyPoints(String companyId, int points) {
    final newCompanyPoints = Map<String, int>.from(companyPoints);
    newCompanyPoints[companyId] = points;
    return copyWith(companyPoints: newCompanyPoints);
  }
}
