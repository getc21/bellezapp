import 'package:get/get.dart';
import '../models/payment_method.dart';

class PaymentController extends GetxController {
  
  // Método de pago seleccionado
  final Rx<PaymentMethod> selectedPaymentMethod = PaymentMethod.cash.obs;
  
  // Estados de validación
  final RxBool isValidatingPayment = false.obs;
  final RxString validationError = ''.obs;
  
  // Información de pago adicional
  final RxString cardReference = ''.obs;
  final RxString transferReference = ''.obs;
  final RxDouble receivedCashAmount = 0.0.obs;
  final RxDouble changeAmount = 0.0.obs;
  
  // Resetear información de pago
  void resetPaymentInfo() {
    selectedPaymentMethod.value = PaymentMethod.cash;
    validationError.value = '';
    cardReference.value = '';
    transferReference.value = '';
    receivedCashAmount.value = 0.0;
    changeAmount.value = 0.0;
  }
  
  // Seleccionar método de pago
  void selectPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
    validationError.value = '';
    
    // Limpiar datos de otros métodos
    if (!method.isCash) {
      receivedCashAmount.value = 0.0;
      changeAmount.value = 0.0;
    }
    if (!method.isCard) {
      cardReference.value = '';
    }
    if (!method.isTransfer) {
      transferReference.value = '';
    }
  }
  
  // Actualizar monto recibido en efectivo
  void updateReceivedCashAmount(double amount) {
    receivedCashAmount.value = amount;
  }
  
  // Calcular cambio
  void calculateChange(double totalAmount) {
    if (selectedPaymentMethod.value.isCash && receivedCashAmount.value > 0) {
      changeAmount.value = receivedCashAmount.value - totalAmount;
    } else {
      changeAmount.value = 0.0;
    }
  }
  
  // Actualizar referencia de tarjeta
  void updateCardReference(String reference) {
    cardReference.value = reference;
  }
  
  // Actualizar referencia de transferencia
  void updateTransferReference(String reference) {
    transferReference.value = reference;
  }
  
  // Validar pago antes de procesar
  bool validatePayment(double totalAmount) {
    validationError.value = '';
    
    switch (selectedPaymentMethod.value) {
      case PaymentMethod.cash:
        if (receivedCashAmount.value <= 0) {
          validationError.value = 'Debe ingresar el monto recibido en efectivo';
          return false;
        }
        if (receivedCashAmount.value < totalAmount) {
          validationError.value = 'El monto recibido es menor al total de la venta';
          return false;
        }
        break;
        
      case PaymentMethod.card:
        if (cardReference.value.trim().isEmpty) {
          validationError.value = 'Debe ingresar la referencia de la tarjeta';
          return false;
        }
        if (cardReference.value.trim().length < 4) {
          validationError.value = 'La referencia debe tener al menos 4 caracteres';
          return false;
        }
        break;
        
      case PaymentMethod.transfer:
        if (transferReference.value.trim().isEmpty) {
          validationError.value = 'Debe ingresar la referencia de la transferencia';
          return false;
        }
        if (transferReference.value.trim().length < 6) {
          validationError.value = 'La referencia debe tener al menos 6 caracteres';
          return false;
        }
        break;
    }
    
    return true;
  }
  
  // Validar sin modificar estado - para uso durante build
  bool isPaymentValid(double totalAmount) {
    switch (selectedPaymentMethod.value) {
      case PaymentMethod.cash:
        return receivedCashAmount.value > 0 && receivedCashAmount.value >= totalAmount;
        
      case PaymentMethod.card:
        return cardReference.value.trim().length >= 4;
        
      case PaymentMethod.transfer:
        return transferReference.value.trim().length >= 6;
    }
  }
  
  // Obtener mensaje de error sin modificar estado
  String getValidationMessage(double totalAmount) {
    switch (selectedPaymentMethod.value) {
      case PaymentMethod.cash:
        if (receivedCashAmount.value <= 0) {
          return 'Debe ingresar el monto recibido en efectivo';
        }
        if (receivedCashAmount.value < totalAmount) {
          return 'El monto recibido es menor al total de la venta';
        }
        break;
        
      case PaymentMethod.card:
        if (cardReference.value.trim().isEmpty) {
          return 'Debe ingresar la referencia de la tarjeta';
        }
        if (cardReference.value.trim().length < 4) {
          return 'La referencia debe tener al menos 4 caracteres';
        }
        break;
        
      case PaymentMethod.transfer:
        if (transferReference.value.trim().isEmpty) {
          return 'Debe ingresar la referencia de la transferencia';
        }
        if (transferReference.value.trim().length < 6) {
          return 'La referencia debe tener al menos 6 caracteres';
        }
        break;
    }
    
    return '';
  }
  
  // Obtener información del pago para mostrar
  Map<String, dynamic> getPaymentInfo() {
    return {
      'method': selectedPaymentMethod.value,
      'methodValue': selectedPaymentMethod.value.value,
      'methodDisplayName': selectedPaymentMethod.value.displayName,
      'cardReference': cardReference.value,
      'transferReference': transferReference.value,
      'receivedAmount': receivedCashAmount.value,
      'changeAmount': changeAmount.value,
    };
  }
  
  // Obtener detalles del pago como texto
  String getPaymentDetails(double totalAmount) {
    final method = selectedPaymentMethod.value;
    String details = '${method.icon} ${method.displayName}';
    
    switch (method) {
      case PaymentMethod.cash:
        if (receivedCashAmount.value > 0) {
          details += '\nRecibido: \$${receivedCashAmount.value.toStringAsFixed(2)}';
          if (changeAmount.value > 0) {
            details += '\nCambio: \$${changeAmount.value.toStringAsFixed(2)}';
          }
        }
        break;
        
      case PaymentMethod.card:
        if (cardReference.value.isNotEmpty) {
          details += '\nRef: ${cardReference.value}';
        }
        break;
        
      case PaymentMethod.transfer:
        if (transferReference.value.isNotEmpty) {
          details += '\nRef: ${transferReference.value}';
        }
        break;
    }
    
    return details;
  }
  
  // Obtener resumen del pago para la orden
  Map<String, dynamic> getPaymentSummary() {
    final info = getPaymentInfo();
    return {
      'payment_method': info['methodValue'],
      'payment_details': {
        'method': info['methodDisplayName'],
        'card_reference': info['cardReference'],
        'transfer_reference': info['transferReference'],
        'received_amount': info['receivedAmount'],
        'change_amount': info['changeAmount'],
      }
    };
  }
  
  // Verificar si se puede procesar el pago
  bool canProcessPayment(double totalAmount) {
    return isPaymentValid(totalAmount) && !isValidatingPayment.value;
  }
}