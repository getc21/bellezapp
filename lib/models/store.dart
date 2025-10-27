class Store {
  final int? id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String status;
  final DateTime createdAt;

  Store({
    this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.status = 'active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Crear Store desde Map
  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convertir Store a Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Método copyWith para crear copias con modificaciones
  Store copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? status,
    DateTime? createdAt,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isActive => status == 'active';

  @override
  String toString() {
    return 'Store{id: $id, name: $name, address: $address, phone: $phone, email: $email, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Store && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
