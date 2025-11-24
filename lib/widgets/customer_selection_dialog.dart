import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bellezapp/controllers/customer_controller.dart';
import 'package:bellezapp/pages/add_customer_page.dart';

class CustomerSelectionDialog extends StatefulWidget {
  final Map<String, dynamic>? suggestedCustomer;
  
  const CustomerSelectionDialog({super.key, this.suggestedCustomer});

  @override
  State<CustomerSelectionDialog> createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  final CustomerController customerController = Get.find<CustomerController>();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    customerController.loadCustomers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredCustomers {
    if (searchQuery.isEmpty) {
      return customerController.customers;
    }
    return customerController.customers.where((customer) {
      return (customer['name']?.toString() ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
             ((customer['email']?.toString() ?? '').toLowerCase().contains(searchQuery.toLowerCase())) ||
             (customer['phone']?.toString() ?? '').contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Seleccionar Cliente',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cliente por nombre, email o teléfono...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Option to add new customer (PRIMERO)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(Icons.person_add, color: Colors.green[700]),
                        ),
                        title: const Text(
                          'Agregar nuevo cliente',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text('Registrar un cliente nuevo'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showAddCustomerDialog(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Option to continue without customer (SEGUNDO)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.person_off, color: Colors.grey[600]),
                        ),
                        title: const Text(
                          'Continuar sin cliente',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text('La venta no se asociará a ningún cliente'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.of(context).pop(null),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Cliente sugerido (si existe)
                    if (widget.suggestedCustomer != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.recommend, color: Colors.blue[700], size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Cliente sugerido',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    (widget.suggestedCustomer!['name']?.toString() ?? '').isNotEmpty 
                                        ? widget.suggestedCustomer!['name'][0].toUpperCase() 
                                        : 'C',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  widget.suggestedCustomer!['name']?.toString() ?? 'Sin nombre',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  '${widget.suggestedCustomer!['loyaltyPoints'] ?? 0} pts • ${widget.suggestedCustomer!['lastPurchase'] ?? 'Sin compras'}',
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(widget.suggestedCustomer!['_id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Seleccionar', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 4. Lista de clientes (AL FINAL)
                    Text(
                      'Todos los clientes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      if (customerController.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final customers = filteredCustomers;

                      if (customers.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty 
                                    ? 'No hay clientes registrados'
                                    : 'No se encontraron clientes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: customers.map((customer) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  (customer['name']?.toString() ?? '').isNotEmpty ? customer['name'][0].toUpperCase() : 'C',
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                customer['name']?.toString() ?? 'Sin nombre',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(customer['email']?.toString() ?? 'Sin email'),
                                  Text(customer['phone']?.toString() ?? 'Sin teléfono'),
                                  Text(
                                    '💰 \$${customer['totalSpent'] ?? 0} • 🛍️ ${customer['orderCount'] ?? 0} compras',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${customer['loyaltyPoints'] ?? 0} puntos de lealtad',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.of(context).pop(customer['_id']),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog() async {
    // Navegar a la página de agregar cliente
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddCustomerPage(),
      ),
    );

    // Si se agregó un cliente exitosamente, recargar la lista y seleccionarlo
    if (result == true) {
      await customerController.loadCustomers();
      
      // Seleccionar automáticamente el último cliente agregado y cerrar el diálogo
      if (customerController.customers.isNotEmpty && mounted) {
        final lastCustomer = customerController.customers.last;
        // Cerrar el diálogo de selección de cliente y devolver el ID del nuevo cliente
        Navigator.of(context).pop(lastCustomer['_id']);
      }
    }
  }
}
