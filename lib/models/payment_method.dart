enum PaymentMethod {
  cash('efectivo', 'Efectivo', '💰'),
  card('tarjeta', 'Tarjeta', '💳'),
  transfer('transferencia', 'Transferencia', '📱');

  const PaymentMethod(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }

  String get displayLabel => '$icon $displayName';

  bool get isCash => this == PaymentMethod.cash;
  bool get isCard => this == PaymentMethod.card;
  bool get isTransfer => this == PaymentMethod.transfer;
}