import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/discount_controller.dart';
import '../models/discount.dart';
import 'add_discount_page.dart';

class DiscountListPage extends StatelessWidget {
  final DiscountController discountController = Get.put(DiscountController());

  DiscountListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Descuentos'),
        backgroundColor: Utils.colorBotones,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => discountController.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[50],
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar descuentos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => discountController.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => discountController.clearSearch(),
                      )
                    : const SizedBox.shrink()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => discountController.searchDiscounts(value),
            ),
          ),
          
          // Estadísticas rápidas
          Obx(() {
            final totalDiscounts = discountController.discounts.length;
            final activeDiscounts = discountController.discounts
                .where((d) => d.isActive)
                .length;
            final percentageDiscounts = discountController.discounts
                .where((d) => d.type == DiscountType.percentage)
                .length;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Total', totalDiscounts.toString(), Colors.blue),
                  _buildStatCard('Activos', activeDiscounts.toString(), Colors.green),
                  _buildStatCard('Porcentaje', percentageDiscounts.toString(), Colors.orange),
                ],
              ),
            );
          }),
          
          // Lista de descuentos
          Expanded(
            child: Obx(() {
              if (discountController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (discountController.filteredDiscounts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.discount_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        discountController.searchQuery.value.isEmpty
                            ? 'No hay descuentos registrados'
                            : 'No se encontraron descuentos',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        discountController.searchQuery.value.isEmpty
                            ? 'Agrega tu primer descuento usando el botón +'
                            : 'Intenta con otros términos de búsqueda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: discountController.refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: discountController.filteredDiscounts.length,
                  itemBuilder: (context, index) {
                    final discount = discountController.filteredDiscounts[index];
                    return _buildDiscountCard(context, discount);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AddDiscountPage()),
        backgroundColor: Utils.colorBotones,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard(BuildContext context, Discount discount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    discount.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDiscountTypeChip(discount.type),
                const SizedBox(width: 8),
                _buildActiveStatusChip(discount.isActive),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              discount.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Valor del descuento
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Text(
                discount.displayValue,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Condiciones
            if (discount.minimumAmount != null || 
                discount.maximumDiscount != null ||
                discount.startDate != null ||
                discount.endDate != null)
              _buildConditionsSection(discount),
            
            const SizedBox(height: 12),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    discount.isActive ? Icons.toggle_on : Icons.toggle_off,
                    color: discount.isActive ? Colors.green : Colors.grey,
                    size: 30,
                  ),
                  onPressed: () => _toggleDiscountStatus(discount),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editDiscount(discount),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteDiscount(context, discount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountTypeChip(DiscountType type) {
    Color color;
    String label;
    
    switch (type) {
      case DiscountType.percentage:
        color = Colors.orange;
        label = '%';
        break;
      case DiscountType.fixed:
        color = Colors.blue;
        label = '\$';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActiveStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isActive ? Colors.green : Colors.grey).withOpacity(0.3),
        ),
      ),
      child: Text(
        isActive ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildConditionsSection(Discount discount) {
    List<Widget> conditions = [];
    
    if (discount.minimumAmount != null) {
      conditions.add(_buildConditionChip(
        'Min: \$${discount.minimumAmount!.toStringAsFixed(2)}',
        Colors.purple,
      ));
    }
    
    if (discount.maximumDiscount != null) {
      conditions.add(_buildConditionChip(
        'Max: \$${discount.maximumDiscount!.toStringAsFixed(2)}',
        Colors.red,
      ));
    }
    
    if (discount.startDate != null) {
      conditions.add(_buildConditionChip(
        'Desde: ${discount.startDate!.day}/${discount.startDate!.month}/${discount.startDate!.year}',
        Colors.blue,
      ));
    }
    
    if (discount.endDate != null) {
      conditions.add(_buildConditionChip(
        'Hasta: ${discount.endDate!.day}/${discount.endDate!.month}/${discount.endDate!.year}',
        Colors.orange,
      ));
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: conditions,
    );
  }

  Widget _buildConditionChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  void _toggleDiscountStatus(Discount discount) {
    discountController.toggleDiscountStatus(discount.id!);
  }

  void _editDiscount(Discount discount) {
    Get.to(() => AddDiscountPage(discount: discount));
  }

  void _deleteDiscount(BuildContext context, Discount discount) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar el descuento "${discount.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              discountController.deleteDiscount(discount.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}