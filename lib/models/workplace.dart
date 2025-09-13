class Workplace {
  final String id;
  final String name;
  final String address;
  final DateTime createdAt;

  Workplace({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Workplace.fromJson(Map<String, dynamic> json) {
    return Workplace(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Workplace copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? createdAt,
  }) {
    return Workplace(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
