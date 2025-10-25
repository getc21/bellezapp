class CashMovement {
  final int? id;
  final String date;
  final String type; // 'apertura', 'cierre', 'venta', 'entrada', 'salida'
  final double amount;
  final String description;
  final int? orderId; // Para relacionar con ventas
  final String? userId; // Para futuro sistema de usuarios

  CashMovement({
    this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.description,
    this.orderId,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'type': type,
      'amount': amount,
      'description': description,
      'order_id': orderId,
      'user_id': userId,
    };
  }

  factory CashMovement.fromMap(Map<String, dynamic> map) {
    return CashMovement(
      id: map['id'],
      date: map['date'],
      type: map['type'],
      amount: map['amount']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      orderId: map['order_id'],
      userId: map['user_id'],
    );
  }

  // Métodos de conveniencia para tipos de movimientos
  static CashMovement apertura(double amount, String date) {
    return CashMovement(
      date: date,
      type: 'apertura',
      amount: amount,
      description: 'Apertura de caja',
    );
  }

  static CashMovement cierre(double amount, String date) {
    return CashMovement(
      date: date,
      type: 'cierre',
      amount: amount,
      description: 'Cierre de caja',
    );
  }

  static CashMovement venta(double amount, String date, int orderId) {
    return CashMovement(
      date: date,
      type: 'venta',
      amount: amount,
      description: 'Venta en efectivo',
      orderId: orderId,
    );
  }

  static CashMovement entrada(double amount, String date, String description) {
    return CashMovement(
      date: date,
      type: 'entrada',
      amount: amount,
      description: description,
    );
  }

  static CashMovement salida(double amount, String date, String description) {
    return CashMovement(
      date: date,
      type: 'salida',
      amount: amount,
      description: description,
    );
  }

  // Getters para UI
  bool get isIncome => type == 'apertura' || type == 'venta' || type == 'entrada';
  bool get isOutcome => type == 'salida';
  bool get isSpecial => type == 'apertura' || type == 'cierre';
  
  // Parsear la fecha string a DateTime
  DateTime get createdAt {
    try {
      // Si la fecha incluye hora (formato: "2024-10-24 10:30:00")
      if (date.contains(' ')) {
        return DateTime.parse(date);
      }
      // Si solo es fecha (formato: "2024-10-24")
      return DateTime.parse(date);
    } catch (e) {
      // Fallback a fecha actual si hay error
      return DateTime.now();
    }
  }
  
  String get formattedAmount {
    final sign = isOutcome ? '-' : '+';
    return '$sign\$${amount.toStringAsFixed(2)}';
  }

  String get typeDisplayName {
    switch (type) {
      case 'apertura':
        return 'Apertura';
      case 'cierre':
        return 'Cierre';
      case 'venta':
        return 'Venta';
      case 'entrada':
        return 'Entrada';
      case 'salida':
        return 'Salida';
      default:
        return 'Desconocido';
    }
  }
}