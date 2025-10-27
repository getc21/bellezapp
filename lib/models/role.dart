class Role {
  final int? id;
  final String name;
  final String? description;

  Role({
    this.id,
    required this.name,
    this.description,
  });

  // Crear Role desde Map
  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
  }

  // Convertir Role a Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
    };
  }

  // Método copyWith
  Role copyWith({
    int? id,
    String? name,
    String? description,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  // Verificar tipo de rol
  bool get isAdmin => name == 'admin';
  bool get isManager => name == 'manager';
  bool get isEmployee => name == 'employee';

  @override
  String toString() {
    return 'Role{id: $id, name: $name, description: $description}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Role && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
