import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/customer_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/customer.dart';
import 'add_customer_page.dart';

class CustomerListPage extends StatelessWidget {
  final CustomerController controller = Get.put(CustomerController());
  final ThemeController themeController = Get.find<ThemeController>();

  CustomerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          // Botón de ordenar
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => _handleSortOption(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Por nombre'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'points',
                child: Row(
                  children: [
                    Icon(Icons.star),
                    SizedBox(width: 8),
                    Text('Por puntos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'spent',
                child: Row(
                  children: [
                    Icon(Icons.attach_money),
                    SizedBox(width: 8),
                    Text('Por gastos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'orders',
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag),
                    SizedBox(width: 8),
                    Text('Por órdenes'),
                  ],
                ),
              ),
            ],
          ),
          Obx(() => controller.isLoading.value
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => controller.refresh(),
                )),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y estadísticas
          _buildHeaderSection(),
          
          // Lista de customers
          Expanded(
            child: Obx(() => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : controller.filteredCustomers.isEmpty
                    ? _buildEmptyState()
                    : _buildCustomerList()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () => _showAddCustomerDialog(context),
        child: const Icon(
          Icons.person_add,
          color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: Theme.of(Get.context!).dividerColor)),
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, teléfono o email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => controller.clearSearch(),
                    )
                  : const SizedBox.shrink()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(Get.context!).colorScheme.surface,
            ),
            onChanged: (value) => controller.searchCustomers(value),
          ),
          
          const SizedBox(height: 16),
          
          // Estadísticas
          Obx(() => Column(
            children: [
              Row(
                children: [
                  _buildStatCard(
                    'Total',
                    controller.totalCustomers.value.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Activos',
                    controller.activeCustomers.value.toString(),
                    Icons.person_outline,
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatCard(
                    'Ingresos',
                    '\$${controller.totalRevenue.value.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.purple,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Puntos',
                    _getTotalLoyaltyPoints().toString(),
                    Icons.star,
                    Colors.orange,
                  ),
                ],
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(Get.context!).dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getTotalLoyaltyPoints() {
    return controller.customers.fold(0, (sum, customer) => sum + customer.loyaltyPoints);
  }

  void _handleSortOption(String sortBy) {
    controller.sortCustomers(sortBy);
  }

  Widget _buildEmptyState() {
    return Obx(() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            controller.searchQuery.value.isNotEmpty 
                ? Icons.search_off 
                : Icons.people_outline,
            size: 80,
            color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'No se encontraron clientes'
                : 'No hay clientes registrados',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'Intenta con otro término de búsqueda'
                : 'Usa el botón + para agregar tu primer cliente',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildCustomerList() {
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = controller.filteredCustomers[index];
        return _buildCustomerCard(customer);
      },
    ));
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCustomerDetails(customer),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(Get.context!).colorScheme.primaryContainer,
                    child: Text(
                      customer.name.isNotEmpty 
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Theme.of(Get.context!).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Información principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Theme.of(Get.context!).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              customer.formattedPhone,
                              style: TextStyle(
                                color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (customer.email != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.email, size: 14, color: Theme.of(Get.context!).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  customer.email!,
                                  style: TextStyle(
                                    color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Menú de opciones
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, customer),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Estadísticas del cliente
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(Get.context!).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            customer.totalSpentFormatted,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Total gastado',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            customer.totalOrders.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'Compras',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            customer.loyaltyPoints.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'Puntos',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            customer.lastPurchaseFormatted,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.purple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Última compra',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    Get.to(() => AddCustomerPage());
  }

  void _showCustomerDetails(Customer customer) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(Get.context!).colorScheme.primaryContainer,
                  child: Text(
                    customer.name.isNotEmpty 
                        ? customer.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(Get.context!).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        customer.customerSince,
                        style: TextStyle(
                          color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildDetailRow('Teléfono', customer.formattedPhone, Icons.phone),
            if (customer.email != null)
              _buildDetailRow('Email', customer.email!, Icons.email),
            if (customer.address != null)
              _buildDetailRow('Dirección', customer.address!, Icons.location_on),
            if (customer.notes != null)
              _buildDetailRow('Notas', customer.notes!, Icons.note),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showEditCustomerDialog(customer);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeController.editColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _confirmDelete(customer);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeController.deleteColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(Get.context!).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Customer customer) {
    switch (action) {
      case 'edit':
        _showEditCustomerDialog(customer);
        break;
      case 'delete':
        _confirmDelete(customer);
        break;
    }
  }

  void _showEditCustomerDialog(Customer customer) {
    Get.to(() => AddCustomerPage(customer: customer));
  }

  void _confirmDelete(Customer customer) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${customer.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteCustomer(customer.id!);
            },
            style: TextButton.styleFrom(foregroundColor: themeController.deleteColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}