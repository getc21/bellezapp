import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_method.dart';
import '../utils/utils.dart';

class PaymentMethodDialog extends StatelessWidget {
  final double totalAmount;
  final VoidCallback? onPaymentConfirmed;
  final PaymentController paymentController = Get.put(PaymentController());

  PaymentMethodDialog({
    super.key,
    required this.totalAmount,
    this.onPaymentConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    // Resetear información de pago al abrir el diálogo
    paymentController.resetPaymentInfo();
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.payment, color: Utils.colorBotones),
          const SizedBox(width: 8),
          const Text('Método de Pago'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6, // Limitar altura
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total de la venta
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Utils.colorBotones.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Utils.colorBotones.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total a Pagar:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Utils.colorBotones,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Selección de método de pago
              _buildPaymentMethodSelection(),
              
              const SizedBox(height: 16),
              
              // Campos adicionales según el método
              Obx(() => _buildAdditionalFields()),
              
              const SizedBox(height: 16),
              
              // Mensaje de error
              Obx(() {
                final errorMessage = paymentController.getValidationMessage(totalAmount);
                return errorMessage.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => _processPayment(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Utils.colorBotones,
            foregroundColor: Colors.white,
          ),
          child: const Text('Procesar Venta'),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona el método de pago:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...PaymentMethod.values.map((method) => _buildPaymentMethodTile(method)),
      ],
    ));
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = paymentController.selectedPaymentMethod.value == method;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 3 : 1,
      color: isSelected ? Utils.colorBotones.withOpacity(0.1) : null,
      child: RadioListTile<PaymentMethod>(
        title: Text(
          method.displayLabel,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: _buildPaymentMethodSubtitle(method),
        value: method,
        groupValue: paymentController.selectedPaymentMethod.value,
        onChanged: (PaymentMethod? value) {
          if (value != null) {
            paymentController.selectPaymentMethod(value);
            paymentController.calculateChange(totalAmount);
          }
        },
        activeColor: Utils.colorBotones,
      ),
    );
  }

  Widget? _buildPaymentMethodSubtitle(PaymentMethod method) {
    // Simplificado por ahora - se puede agregar lógica de caja más tarde
    return null;
  }

  Widget _buildAdditionalFields() {
    final method = paymentController.selectedPaymentMethod.value;
    
    switch (method) {
      case PaymentMethod.cash:
        return _buildCashFields();
      case PaymentMethod.card:
        return _buildCardFields();
      case PaymentMethod.transfer:
        return _buildTransferFields();
    }
  }

  Widget _buildCashFields() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Monto Recibido',
            prefixText: '\$ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Utils.colorBotones, width: 2),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            paymentController.updateReceivedCashAmount(amount);
            paymentController.calculateChange(totalAmount);
          },
        ),
        
        const SizedBox(height: 12),
        
        Obx(() => paymentController.changeAmount.value > 0
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cambio a entregar:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '\$${paymentController.changeAmount.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildCardFields() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Referencia de Tarjeta',
        hintText: 'Últimos 4 dígitos o número de transacción',
        prefixIcon: const Icon(Icons.credit_card),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Utils.colorBotones, width: 2),
        ),
      ),
      onChanged: (value) => paymentController.updateCardReference(value),
    );
  }

  Widget _buildTransferFields() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Referencia de Transferencia',
        hintText: 'Número de operación o referencia',
        prefixIcon: const Icon(Icons.account_balance),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Utils.colorBotones, width: 2),
        ),
      ),
      onChanged: (value) => paymentController.updateTransferReference(value),
    );
  }

  void _processPayment(BuildContext context) {
    // Usar la validación que modifica estado solo al procesar
    if (paymentController.validatePayment(totalAmount)) {
      Navigator.of(context).pop();
      onPaymentConfirmed?.call();
    }
    // Los errores se muestran automáticamente por el Obx
  }
}