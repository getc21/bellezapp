import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/discount_controller.dart';
import '../models/discount.dart';

class DiscountSelectionDialog extends StatefulWidget {
  final double totalAmount;
  final Function(Discount?) onDiscountSelected;

  const DiscountSelectionDialog({
    super.key,
    required this.totalAmount,
    required this.onDiscountSelected,
  });

  @override
  State<DiscountSelectionDialog> createState() => _DiscountSelectionDialogState();
}

class _DiscountSelectionDialogState extends State<DiscountSelectionDialog> {
  late final DiscountController discountController;
  Discount? selectedDiscount;
  
  @override
  void initState() {
    super.initState();
    // Inicializar el controlador
    try {
      discountController = Get.find<DiscountController>();
    } catch (e) {
      print('⚠️ DiscountController no encontrado, creando uno nuevo');
      discountController = Get.put(DiscountController());
    }
    
    // Recargar descuentos y actualizar aplicables
    _loadDiscounts();
  }
  
  Future<void> _loadDiscounts() async {
    print('🔄 Recargando descuentos desde el diálogo...');
    await discountController.loadDiscounts();
    print('📋 Descuentos cargados: ${discountController.discounts.length}');
    // Actualizar descuentos aplicables cuando se abre el diálogo
    discountController.updateApplicableDiscounts(widget.totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.pink),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Seleccionar Descuento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Información del total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total de la compra: \$${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedDiscount != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Descuento: ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          '-\$${selectedDiscount!.calculateDiscountAmount(widget.totalAmount).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Total final: ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          '\$${(widget.totalAmount - selectedDiscount!.calculateDiscountAmount(widget.totalAmount)).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Lista de descuentos aplicables
            Expanded(
              child: Obx(() {
                if (discountController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final applicableDiscounts = discountController.applicableDiscounts;
                
                if (applicableDiscounts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay descuentos disponibles',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Para este monto de compra',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: applicableDiscounts.length + 1, // +1 para la opción "Sin descuento"
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Opción "Sin descuento"
                      return _buildDiscountOption(
                        title: 'Sin descuento',
                        subtitle: 'No aplicar ningún descuento',
                        discount: null,
                        savingsAmount: 0,
                      );
                    }
                    
                    final discount = applicableDiscounts[index - 1];
                    final savingsAmount = discount.calculateDiscountAmount(widget.totalAmount);
                    
                    return _buildDiscountOption(
                      title: discount.name,
                      subtitle: discount.description,
                      discount: discount,
                      savingsAmount: savingsAmount,
                    );
                  },
                );
              }),
            ),
            
            // Botones de acción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onDiscountSelected(selectedDiscount);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[200],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountOption({
    required String title,
    required String subtitle,
    required Discount? discount,
    required double savingsAmount,
  }) {
    final isSelected = selectedDiscount == discount;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.pink[50] : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Radio<Discount?>(
          value: discount,
          groupValue: selectedDiscount,
          onChanged: (value) {
            setState(() {
              selectedDiscount = value;
            });
          },
          activeColor: Colors.pink,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (discount != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      discount.displayValue,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ahorras: \$${savingsAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (discount.minimumAmount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Compra mínima: \$${discount.minimumAmount!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ],
        ),
        onTap: () {
          setState(() {
            selectedDiscount = discount;
          });
        },
      ),
    );
  }
}

// Función helper para mostrar el diálogo
Future<Discount?> showDiscountSelectionDialog({
  required BuildContext context,
  required double totalAmount,
}) async {
  Discount? selectedDiscount;
  
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return DiscountSelectionDialog(
        totalAmount: totalAmount,
        onDiscountSelected: (discount) {
          selectedDiscount = discount;
        },
      );
    },
  );
  
  return selectedDiscount;
}