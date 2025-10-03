class Workplace {
  final String id;
  final String name;
  final String address;
  final DateTime createdAt;
  final String? companyId; // Optional: which company this workplace belongs to

  Workplace({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
    this.companyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'companyId': companyId,
    };
  }

  factory Workplace.fromJson(Map<String, dynamic> json) {
    return Workplace(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      createdAt: DateTime.parse(json['createdAt']),
      companyId: json['companyId'],
    );
  }

  Workplace copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? createdAt,
    String? companyId,
  }) {
    return Workplace(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      companyId: companyId ?? this.companyId,
    );
  }
}
