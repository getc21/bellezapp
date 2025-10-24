class Store {
  final int? id;
  final String name;
  final String code; // Código único de la tienda
  final String address;
  final String? phone;
  final String? email;
  final String? manager;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? settings; // Configuraciones específicas de la tienda

  Store({
    this.id,
    required this.name,
    required this.code,
    required this.address,
    this.phone,
    this.email,
    this.manager,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.settings,
  });

  // Método para convertir desde Map (base de datos)
  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      manager: map['manager'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      settings: map['settings'] != null ? Map<String, dynamic>.from(map['settings']) : null,
    );
  }

  // Método para convertir a Map (base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
      'manager': manager,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'settings': settings,
    };
  }

  // Método para crear una copia con cambios
  Store copyWith({
    int? id,
    String? name,
    String? code,
    String? address,
    String? phone,
    String? email,
    String? manager,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? settings,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      manager: manager ?? this.manager,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() {
    return 'Store(id: $id, name: $name, code: $code, address: $address, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Store && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Getters de conveniencia
  String get displayName => '$name ($code)';
  String get fullAddress => address;
  bool get hasManager => manager != null && manager!.isNotEmpty;
  bool get hasContact => (phone != null && phone!.isNotEmpty) || (email != null && email!.isNotEmpty);
}