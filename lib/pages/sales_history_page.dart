import 'package:bellezapp/controllers/order_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/widgets/store_aware_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  SalesHistoryPageState createState() => SalesHistoryPageState();
}

class SalesHistoryPageState extends State<SalesHistoryPage> {
  late final OrderController orderController;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPaymentMethod;

  final List<String> _paymentMethods = [
    'Todos',
    'efectivo',
    'tarjeta',
    'transferencia',
    'otro',
  ];

  @override
  void initState() {
    super.initState();
    // Usar la misma instancia del controlador que ya existe
    try {
      orderController = Get.find<OrderController>();
    } catch (e) {
      orderController = Get.put(OrderController());
    }
    // Cargar últimos 30 días por defecto
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    await orderController.loadOrders();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Utils.colorBotones,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    List<Map<String, dynamic>> filtered = orderController.orders;

    // Filtrar por fecha
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((order) {
        final orderDate = DateTime.parse(order['orderDate']);
        return orderDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Filtrar por método de pago
    if (_selectedPaymentMethod != null && _selectedPaymentMethod != 'Todos') {
      filtered = filtered.where((order) {
        return order['paymentMethod'] == _selectedPaymentMethod;
      }).toList();
    }

    // Ordenar por fecha descendente (más recientes primero)
    filtered.sort((a, b) {
      final dateA = DateTime.parse(a['orderDate']);
      final dateB = DateTime.parse(b['orderDate']);
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  double _getTotalSales(List<Map<String, dynamic>> orders) {
    return orders.fold(0.0, (sum, order) {
      final total = double.tryParse(order['totalOrden'].toString()) ?? 0.0;
      return sum + total;
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'efectivo':
        return Icons.money;
      case 'tarjeta':
        return Icons.credit_card;
      case 'transferencia':
        return Icons.account_balance;
      default:
        return Icons.payments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: StoreAwareAppBar(
        title: 'Historial de Ventas',
        icon: Icons.trending_up_outlined,
        backgroundColor: Utils.colorBotones,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Selector de rango de fechas
                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                                : 'Seleccionar rango de fechas',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Selector de método de pago
                DropdownButtonFormField<String>(
                  initialValue: _selectedPaymentMethod ?? 'Todos',
                  decoration: InputDecoration(
                    labelText: 'Método de pago',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value == 'Todos' ? null : value;
                    });
                  },
                ),
              ],
            ),
          ),

          // Lista de órdenes
          Expanded(
            child: Obx(() {
              if (orderController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredOrders = _getFilteredOrders();
              final totalSales = _getTotalSales(filteredOrders);

              if (filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay ventas en este período',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Resumen de ventas
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Utils.colorBotones,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Ventas',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatCurrency(totalSales),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Órdenes',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${filteredOrders.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de órdenes
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _buildOrderCard(order);
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final total = double.tryParse(order['totalOrden'].toString()) ?? 0.0;
    final date = _formatDate(order['orderDate']);
    final paymentMethod = order['paymentMethod'] ?? 'otro';
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final itemCount = items.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Utils.colorBotones.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getPaymentIcon(paymentMethod),
            color: Utils.colorBotones,
            size: 28,
          ),
        ),
        title: Text(
          _formatCurrency(total),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(date),
            Text('$paymentMethod • $itemCount item${itemCount != 1 ? 's' : ''}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
