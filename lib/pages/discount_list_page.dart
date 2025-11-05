import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/widgets/store_aware_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/discount_controller.dart';
import 'add_discount_page.dart';

class DiscountListPage extends StatelessWidget {
  final DiscountController discountController = Get.put(DiscountController());

  DiscountListPage({super.key}) {
    print('DiscountListPage - Constructor called');
    print('DiscountListPage - DiscountController instance: $discountController');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StoreAwareAppBar(
        title: 'Gestión de Descuentos',
        icon: Icons.local_offer_outlined,
        backgroundColor: Utils.colorGnav,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async => await discountController.refresh(),
          ),
          // ⭐ BOTÓN DE PRUEBA: Cargar todos los descuentos
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              print('DiscountListPage - Testing: Loading all discounts');
              await discountController.loadAllDiscountsForTesting();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[50],
            child: Container(
              height: 40,
              child: TextField(
                style: TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar descuentos...',
                  hintStyle: TextStyle(fontSize: 12),
                  prefixIcon: Icon(Icons.search, size: 20),
                  suffixIcon: Obx(() => discountController.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18),
                          onPressed: () => discountController.clearSearch(),
                        )
                      : const SizedBox.shrink()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (value) => discountController.searchDiscounts(value),
              ),
            ),
          ),
          
          // Estadísticas rápidas
          Obx(() {
            final totalDiscounts = discountController.discounts.length;
            final activeDiscounts = discountController.discounts
                .where((d) => d['isActive'] ?? false)
                .length;
            final percentageDiscounts = discountController.discounts
                .where((d) => d['type'] == 'percentage')
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
              print('DiscountListPage - Building discount list');
              print('DiscountListPage - IsLoading: ${discountController.isLoading}');
              print('DiscountListPage - Total discounts: ${discountController.discounts.length}');
              print('DiscountListPage - Filtered discounts: ${discountController.filteredDiscounts.length}');
              print('DiscountListPage - Error message: ${discountController.errorMessage}');
              
              if (discountController.isLoading) {
                print('DiscountListPage - Showing loading indicator');
                return const Center(child: CircularProgressIndicator());
              }
              
              if (discountController.filteredDiscounts.isEmpty) {
                print('DiscountListPage - No discounts to show, showing empty state');
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
                        discountController.searchQuery.isEmpty
                            ? 'No hay descuentos registrados'
                            : 'No se encontraron descuentos',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        discountController.searchQuery.isEmpty
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
              
              print('DiscountListPage - Showing discount list with ${discountController.filteredDiscounts.length} items');
              return RefreshIndicator(
                onRefresh: () async => await discountController.refresh(),
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

  Widget _buildDiscountCard(BuildContext context, Map<String, dynamic> discount) {
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
                    discount['name']?.toString() ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDiscountTypeChip(discount['type']?.toString() ?? 'percentage'),
                const SizedBox(width: 8),
                _buildActiveStatusChip(discount['isActive'] ?? false),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              discount['description']?.toString() ?? '',
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
                _getDisplayValue(discount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Condiciones
            if (discount['minimumAmount'] != null || 
                discount['maximumDiscount'] != null ||
                discount['startDate'] != null ||
                discount['endDate'] != null)
              _buildConditionsSection(discount),
            
            const SizedBox(height: 12),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    (discount['isActive'] ?? false) ? Icons.toggle_on : Icons.toggle_off,
                    color: (discount['isActive'] ?? false) ? Colors.green : Colors.grey,
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

  Widget _buildDiscountTypeChip(String type) {
    Color color;
    String label;
    
    switch (type) {
      case 'percentage':
        color = Colors.orange;
        label = '%';
        break;
      case 'fixed':
        color = Colors.blue;
        label = '\$';
        break;
      default:
        color = Colors.grey;
        label = '?';
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

  String _getDisplayValue(Map<String, dynamic> discount) {
    final type = discount['type']?.toString() ?? 'percentage';
    final value = (discount['value'] as num?)?.toDouble() ?? 0.0;
    
    if (type == 'percentage') {
      return '${value.toStringAsFixed(0)}% OFF';
    } else {
      return '\$${value.toStringAsFixed(2)} OFF';
    }
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

  Widget _buildConditionsSection(Map<String, dynamic> discount) {
    List<Widget> conditions = [];
    
    if (discount['minimumAmount'] != null) {
      conditions.add(_buildConditionChip(
        'Min: \$${discount['minimumAmount'].toStringAsFixed(2)}',
        Colors.purple,
      ));
    }
    
    if (discount['maximumDiscount'] != null) {
      conditions.add(_buildConditionChip(
        'Max: \$${discount['maximumDiscount'].toStringAsFixed(2)}',
        Colors.red,
      ));
    }
    
    if (discount['startDate'] != null) {
      final startDate = DateTime.parse(discount['startDate']);
      conditions.add(_buildConditionChip(
        'Desde: ${startDate.day}/${startDate.month}/${startDate.year}',
        Colors.blue,
      ));
    }
    
    if (discount['endDate'] != null) {
      final endDate = DateTime.parse(discount['endDate']);
      conditions.add(_buildConditionChip(
        'Hasta: ${endDate.day}/${endDate.month}/${endDate.year}',
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

  void _toggleDiscountStatus(Map<String, dynamic> discount) {
    discountController.toggleDiscountStatus(discount['_id']!.toString());
  }

  void _editDiscount(Map<String, dynamic> discount) {
    Get.to(() => AddDiscountPage(discount: discount));
  }

  void _deleteDiscount(BuildContext context, Map<String, dynamic> discount) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar el descuento "${discount['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              print('DiscountListPage - Deleting discount: ${discount['name']}');
              final success = await discountController.deleteDiscount(discount['_id']!.toString());
              if (success) {
                print('DiscountListPage - Discount deleted successfully, list should update automatically');
              } else {
                print('DiscountListPage - Failed to delete discount');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}