class User {
  final int? id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String passwordHash;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? profileImageUrl;
  final String? phone;
  final Map<String, dynamic>? permissions;
  final int? storeId; // Tienda asignada (null para admin que puede ver todas)

  User({
    this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.passwordHash,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.profileImageUrl,
    this.phone,
    this.permissions,
    this.storeId,
  });

  // Getters de conveniencia
  String get fullName => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';
  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager;
  bool get isEmployee => role == UserRole.employee;
  bool get hasStoreRestriction => !isAdmin && storeId != null;

  // Conversión a Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'password_hash': passwordHash,
      'role': role.name,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'profile_image_url': profileImageUrl,
      'phone': phone,
      'permissions': permissions != null ? _mapToJson(permissions!) : null,
      'store_id': storeId,
    };
  }

  // Crear desde Map de la base de datos
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      passwordHash: map['password_hash'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == map['role'],
        orElse: () => UserRole.employee,
      ),
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      lastLoginAt: map['last_login_at'] != null 
          ? DateTime.parse(map['last_login_at'])
          : null,
      profileImageUrl: map['profile_image_url'],
      phone: map['phone'],
      permissions: map['permissions'] != null 
          ? _jsonToMap(map['permissions'])
          : null,
      storeId: map['store_id'],
    );
  }

  // Métodos para verificar permisos
  bool hasPermission(String permission) {
    if (isAdmin) return true; // Admin tiene todos los permisos
    if (permissions == null) return false;
    return permissions![permission] == true;
  }

  bool canManageUsers() => hasPermission('manage_users') || isAdmin;
  bool canManageProducts() => hasPermission('manage_products') || isAdmin || isManager;
  bool canManageOrders() => hasPermission('manage_orders') || isAdmin || isManager;
  bool canManageCustomers() => hasPermission('manage_customers') || isAdmin || isManager;
  bool canManageDiscounts() => hasPermission('manage_discounts') || isAdmin || isManager;
  bool canViewReports() => hasPermission('view_reports') || isAdmin || isManager;
  bool canManageInventory() => hasPermission('manage_inventory') || isAdmin || isManager;
  bool canManageCash() => hasPermission('manage_cash') || isAdmin || isManager;

  // Copiar con cambios
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? passwordHash,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? profileImageUrl,
    String? phone,
    Map<String, dynamic>? permissions,
    int? storeId,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phone: phone ?? this.phone,
      permissions: permissions ?? this.permissions,
      storeId: storeId ?? this.storeId,
    );
  }

  // Métodos auxiliares para JSON (implementación simple)
  static String _mapToJson(Map<String, dynamic> map) {
    // Simple implementación, en producción usar dart:convert
    final entries = map.entries.map((e) => '"${e.key}":${e.value is String ? '"${e.value}"' : e.value}');
    return '{${entries.join(',')}}';
  }

  static Map<String, dynamic> _jsonToMap(String json) {
    // Simple implementación, en producción usar dart:convert
    // Por ahora devolvemos mapa vacío
    return <String, dynamic>{};
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, fullName: $fullName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum UserRole {
  admin('Administrador'),
  manager('Gerente'),
  employee('Empleado');

  const UserRole(this.displayName);
  final String displayName;

  // Permisos por defecto según el rol
  Map<String, bool> get defaultPermissions {
    switch (this) {
      case UserRole.admin:
        return {
          'manage_users': true,
          'manage_products': true,
          'manage_orders': true,
          'manage_customers': true,
          'manage_discounts': true,
          'view_reports': true,
          'manage_inventory': true,
          'manage_cash': true,
          'manage_settings': true,
        };
      case UserRole.manager:
        return {
          'manage_users': false,
          'manage_products': true,
          'manage_orders': true,
          'manage_customers': true,
          'manage_discounts': true,
          'view_reports': true,
          'manage_inventory': true,
          'manage_cash': true,
          'manage_settings': false,
        };
      case UserRole.employee:
        return {
          'manage_users': false,
          'manage_products': false,
          'manage_orders': true,
          'manage_customers': true,
          'manage_discounts': false,
          'view_reports': false,
          'manage_inventory': false,
          'manage_cash': false,
          'manage_settings': false,
        };
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Acceso completo al sistema';
      case UserRole.manager:
        return 'Gestión de operaciones y reportes';
      case UserRole.employee:
        return 'Operaciones básicas de venta';
    }
  }
}