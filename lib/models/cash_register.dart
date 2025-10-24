class CashRegister {
  final int? id;
  final String date;
  final double openingAmount;
  final double? closingAmount;
  final double? expectedAmount;
  final double? difference;
  final String status; // 'abierta', 'cerrada'
  final String? openingTime;
  final String? closingTime;
  final String? userId;

  CashRegister({
    this.id,
    required this.date,
    required this.openingAmount,
    this.closingAmount,
    this.expectedAmount,
    this.difference,
    required this.status,
    this.openingTime,
    this.closingTime,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'opening_amount': openingAmount,
      'closing_amount': closingAmount,
      'expected_amount': expectedAmount,
      'difference': difference,
      'status': status,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'user_id': userId,
    };
  }

  factory CashRegister.fromMap(Map<String, dynamic> map) {
    return CashRegister(
      id: map['id'],
      date: map['date'],
      openingAmount: map['opening_amount']?.toDouble() ?? 0.0,
      closingAmount: map['closing_amount']?.toDouble(),
      expectedAmount: map['expected_amount']?.toDouble(),
      difference: map['difference']?.toDouble(),
      status: map['status'] ?? 'abierta',
      openingTime: map['opening_time'],
      closingTime: map['closing_time'],
      userId: map['user_id'],
    );
  }

  // Factory constructors
  static CashRegister open(double openingAmount, String date) {
    final now = DateTime.now();
    return CashRegister(
      date: date,
      openingAmount: openingAmount,
      status: 'abierta',
      openingTime: now.toIso8601String(),
    );
  }

  CashRegister close(double closingAmount, double expectedAmount) {
    final now = DateTime.now();
    final diff = closingAmount - expectedAmount;
    
    return CashRegister(
      id: id,
      date: date,
      openingAmount: openingAmount,
      closingAmount: closingAmount,
      expectedAmount: expectedAmount,
      difference: diff,
      status: 'cerrada',
      openingTime: openingTime,
      closingTime: now.toIso8601String(),
      userId: userId,
    );
  }

  // Getters para UI
  bool get isOpen => status == 'abierta';
  bool get isClosed => status == 'cerrada';
  
  double get totalSales {
    if (expectedAmount == null || openingAmount == 0) return 0.0;
    return expectedAmount! - openingAmount;
  }

  bool get hasDifference {
    return difference != null && difference!.abs() > 0.01; // Tolerancia de centavos
  }

  bool get isShort => difference != null && difference! < 0;
  bool get isOver => difference != null && difference! > 0;

  String get differenceDisplayText {
    if (difference == null) return '';
    if (difference!.abs() <= 0.01) return 'Exacto';
    if (isShort) return 'Faltante: \$${difference!.abs().toStringAsFixed(2)}';
    return 'Sobrante: \$${difference!.toStringAsFixed(2)}';
  }

  String get formattedOpeningAmount => '\$${openingAmount.toStringAsFixed(2)}';
  String get formattedClosingAmount => closingAmount != null ? '\$${closingAmount!.toStringAsFixed(2)}' : 'N/A';
  String get formattedExpectedAmount => expectedAmount != null ? '\$${expectedAmount!.toStringAsFixed(2)}' : 'N/A';
  String get formattedTotalSales => '\$${totalSales.toStringAsFixed(2)}';

  String get formattedOpeningTime {
    if (openingTime == null) return 'N/A';
    final time = DateTime.parse(openingTime!);
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String get formattedClosingTime {
    if (closingTime == null) return 'N/A';
    final time = DateTime.parse(closingTime!);
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String get statusDisplayName {
    switch (status) {
      case 'abierta':
        return 'Abierta';
      case 'cerrada':
        return 'Cerrada';
      default:
        return 'Desconocido';
    }
  }
}