import 'package:bellezapp/controllers/order_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/widgets/store_aware_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({super.key});

  @override
  FinancialReportPageState createState() => FinancialReportPageState();
}

class FinancialReportPageState extends State<FinancialReportPage> {
  late final OrderController orderController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Usar la misma instancia del controlador que ya existe
    try {
      orderController = Get.find<OrderController>();
    } catch (e) {
      orderController = Get.put(OrderController());
    }
    // Últimos 30 días por defecto
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    orderController.loadOrders();
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
    if (_startDate == null || _endDate == null) {
      return orderController.orders;
    }

    return orderController.orders.where((order) {
      final orderDate = DateTime.parse(order['orderDate']);
      return orderDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
          orderDate.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, dynamic> _calculateFinancialData(List<Map<String, dynamic>> orders) {
    double totalIncome = 0.0;
    int totalOrders = orders.length;
    
    Map<String, int> ordersPerDay = {};
    Map<String, double> incomePerDay = {};

    for (var order in orders) {
      final total = double.tryParse(order['totalOrden'].toString()) ?? 0.0;
      totalIncome += total;

      final date = DateTime.parse(order['orderDate']);
      final dateKey = DateFormat('dd/MM').format(date);
      
      ordersPerDay[dateKey] = (ordersPerDay[dateKey] ?? 0) + 1;
      incomePerDay[dateKey] = (incomePerDay[dateKey] ?? 0.0) + total;
    }

    final averageOrderValue = totalOrders > 0 ? totalIncome / totalOrders : 0.0;

    return {
      'totalIncome': totalIncome,
      'totalOrders': totalOrders,
      'averageOrderValue': averageOrderValue,
      'ordersPerDay': ordersPerDay,
      'incomePerDay': incomePerDay,
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
        title: 'Reporte Financiero',
        icon: Icons.monetization_on_outlined,
        backgroundColor: Utils.colorBotones,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => orderController.loadOrders(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de rango de fechas
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: InkWell(
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
          ),

          // Contenido
          Expanded(
            child: Obx(() {
              if (orderController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredOrders = _getFilteredOrders();
              
              if (filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assessment_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay datos financieros en este período',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final financialData = _calculateFinancialData(filteredOrders);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Resumen principal
                    _buildMainSummary(financialData),
                    const SizedBox(height: 16),

                    // Promedio por orden
                    _buildAverageCard(financialData),
                    const SizedBox(height: 16),

                    // Ingresos por día
                    _buildDailyIncomeCard(financialData),
                    const SizedBox(height: 16),

                    // Nota
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
                              'Este reporte muestra datos básicos. Para análisis avanzados (balance, gastos, gráficos) se requieren endpoints adicionales.',
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
          ),
        ],
      ),
    );
  }

  Widget _buildMainSummary(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Utils.colorBotones, Utils.colorBotones.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'Ingresos Totales',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(data['totalIncome']),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${data['totalOrders']} órdenes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageCard(Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Promedio por Orden',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(data['averageOrderValue']),
                    style: const TextStyle(
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
    );
  }

  Widget _buildDailyIncomeCard(Map<String, dynamic> data) {
    final incomePerDay = data['incomePerDay'] as Map<String, double>;
    final entries = incomePerDay.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresos por Día (Top 5)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...entries.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
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
}
