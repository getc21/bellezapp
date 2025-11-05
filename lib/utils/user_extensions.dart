// Extensiones para trabajar con Map<String, dynamic> como User
extension UserMapExtension on Map<String, dynamic> {
  String? get id => this['id'] ?? this['_id'];
  String get username => this['username'] ?? '';
  String get email => this['email'] ?? '';
  String get firstName => this['firstName'] ?? '';
  String get lastName => this['lastName'] ?? '';
  String get role => this['role'] ?? 'employee';
  bool get isActive => this['isActive'] ?? true;
  String? get phone => this['phone'];
  DateTime? get createdAt {
    final value = this['createdAt'];
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
  DateTime? get lastLoginAt {
    final value = this['lastLoginAt'];
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
  
  String get fullName {
    final first = firstName;
    final last = lastName;
    if (first.isEmpty && last.isEmpty) return username;
    return '$first $last'.trim();
  }
  
  String get initials {
    final first = firstName;
    final last = lastName;
    String result = '';
    if (first.isNotEmpty) result += first[0].toUpperCase();
    if (last.isNotEmpty) result += last[0].toUpperCase();
    return result.isEmpty ? 'U' : result;
  }
  
  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Gerente';
      case 'employee':
        return 'Empleado';
      default:
        return 'Usuario';
    }
  }
}
