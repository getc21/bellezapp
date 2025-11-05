import 'package:bellezapp/controllers/order_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/widgets/store_aware_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  ReportPageState createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  late final OrderController orderController;

  @override
  void initState() {
    super.initState();
    // Usar la misma instancia del controlador que ya existe
    try {
      orderController = Get.find<OrderController>();
    } catch (e) {
      orderController = Get.put(OrderController());
    }
    orderController.loadOrders();
  }

  Map<String, dynamic> _getStatistics() {
    final orders = orderController.orders;
    
    // Total ventas
    final totalSales = orders.fold(0.0, (sum, order) {
      return sum + (double.tryParse(order['totalOrden'].toString()) ?? 0.0);
    });

    // Productos más vendidos (simplificado)
    final Map<String, int> productCount = {};
    for (var order in orders) {
      final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
      for (var item in items) {
        final productId = item['productId'].toString();
        final quantity = int.tryParse(item['quantity'].toString()) ?? 0;
        productCount[productId] = (productCount[productId] ?? 0) + quantity;
      }
    }

    // Ventas por método de pago
    final Map<String, double> salesByPayment = {};
    for (var order in orders) {
      final method = order['paymentMethod'] ?? 'otro';
      final total = double.tryParse(order['totalOrden'].toString()) ?? 0.0;
      salesByPayment[method] = (salesByPayment[method] ?? 0.0) + total;
    }

    return {
      'totalOrders': orders.length,
      'totalSales': totalSales,
      'productsSold': productCount.values.fold(0, (sum, qty) => sum + qty),
      'salesByPayment': salesByPayment,
      'topProducts': productCount,
    };
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: StoreAwareAppBar(
        title: 'Reportes',
        icon: Icons.insert_chart_outlined,
        backgroundColor: Utils.colorBotones,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => orderController.loadOrders(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Obx(() {
        if (orderController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderController.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assessment_outlined,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay datos para generar reportes',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final stats = _getStatistics();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de resumen general
              _buildSummaryCard(stats),
              const SizedBox(height: 16),

              // Ventas por método de pago
              _buildPaymentMethodsCard(stats['salesByPayment']),
              const SizedBox(height: 16),

              // Nota informativa
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reportes avanzados (rotación, análisis financiero) requieren endpoints adicionales en el backend.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Ventas',
                    _formatCurrency(stats['totalSales']),
                    Icons.attach_money,
                    Utils.colorBotones,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Órdenes',
                    stats['totalOrders'].toString(),
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              'Productos Vendidos',
              stats['productsSold'].toString(),
              Icons.inventory_2,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard(Map<String, double> salesByPayment) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas por Método de Pago',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...salesByPayment.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getPaymentIcon(entry.key),
                          color: Utils.colorBotones,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatCurrency(entry.value),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
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
}
