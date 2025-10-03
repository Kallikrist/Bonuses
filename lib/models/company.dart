class Company {
  final String id;
  final String name;
  final String? address;
  final String? contactEmail;
  final String? contactPhone;
  final String adminUserId; // The admin who owns/manages this company
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    this.address,
    this.contactEmail,
    this.contactPhone,
    required this.adminUserId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'adminUserId': adminUserId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      adminUserId: json['adminUserId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Company copyWith({
    String? id,
    String? name,
    String? address,
    String? contactEmail,
    String? contactPhone,
    String? adminUserId,
    DateTime? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      adminUserId: adminUserId ?? this.adminUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
