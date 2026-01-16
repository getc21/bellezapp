import 'package:bellezapp/controllers/store_controller.dart';
import 'package:bellezapp/controllers/expense_controller.dart';
import 'package:bellezapp/models/expense.dart';
import 'package:bellezapp/utils/icon_mapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExpenseComparisonPage extends StatefulWidget {
  const ExpenseComparisonPage({super.key});

  @override
  ExpenseComparisonPageState createState() => ExpenseComparisonPageState();
}

class ExpenseComparisonPageState extends State<ExpenseComparisonPage> {
  final storeController = Get.find<StoreController>();
  final expenseController = Get.find<ExpenseController>();

  DateTime _periodOneStart = DateTime.now().subtract(Duration(days: 60));
  DateTime _periodOneEnd = DateTime.now().subtract(Duration(days: 30));
  DateTime _periodTwoStart = DateTime.now().subtract(Duration(days: 30));
  DateTime _periodTwoEnd = DateTime.now();

  ExpensePeriodComparison? _comparison;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComparison();
    });
  }

  Future<void> _loadComparison() async {
    final currentStore = storeController.currentStore;
    if (currentStore != null) {
      final result = await expenseController.compareExpensePeriods(
        storeId: currentStore['_id'],
        startDate1: _periodOneStart,
        endDate1: _periodOneEnd,
        startDate2: _periodTwoStart,
        endDate2: _periodTwoEnd,
      );
      setState(() {
        _comparison = result;
      });
    }
  }

  Future<void> _selectPeriodOne() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _periodOneStart, end: _periodOneEnd),
    );

    if (pickedRange != null) {
      setState(() {
        _periodOneStart = pickedRange.start;
        _periodOneEnd = pickedRange.end;
      });
      await _loadComparison();
    }
  }

  Future<void> _selectPeriodTwo() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _periodTwoStart, end: _periodTwoEnd),
    );

    if (pickedRange != null) {
      setState(() {
        _periodTwoStart = pickedRange.start;
        _periodTwoEnd = pickedRange.end;
      });
      await _loadComparison();
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  Color _getChangeColor(double percentage) {
    if (percentage > 0) return Colors.red;
    if (percentage < 0) return Colors.green;
    return Colors.grey;
  }

  String _getChangeIcon(double percentage) {
    if (percentage > 0) return '📈';
    if (percentage < 0) return '📉';
    return '↔️';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparar Períodos'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadComparison,
        child: Obx(
          () => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de Período 1
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Período 1',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectPeriodOne,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_formatDate(_periodOneStart)} - ${_formatDate(_periodOneEnd)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Icon(Icons.calendar_today, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de Período 2
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Período 2',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectPeriodTwo,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_formatDate(_periodTwoStart)} - ${_formatDate(_periodTwoEnd)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Icon(Icons.calendar_today, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Comparación
                if (expenseController.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_comparison != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resumen de Totales
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumen de Comparación',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),

                              // Período 1
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Período 1',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatCurrency(_comparison!.totalExpensePeriodOne),
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      Text(
                                        '${_comparison!.countPeriodOne} transacciones',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Promedio',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatCurrency(_comparison!.averagePeriodOne),
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              // Período 2
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Período 2',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatCurrency(_comparison!.totalExpensePeriodTwo),
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      Text(
                                        '${_comparison!.countPeriodTwo} transacciones',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Promedio',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatCurrency(_comparison!.averagePeriodTwo),
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              // Diferencia
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getChangeColor(_comparison!.percentageChange).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cambio',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(_comparison!.difference),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: _getChangeColor(_comparison!.percentageChange),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Porcentaje',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_getChangeIcon(_comparison!.percentageChange)} ${_comparison!.percentageChange.toStringAsFixed(2)}%',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: _getChangeColor(_comparison!.percentageChange),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Por Categoría
                      if (_comparison!.byCategory.isNotEmpty) ...[
                        Text(
                          'Comparación por Categoría',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ..._comparison!.byCategory.map((category) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Encabezado con categoría
                                  Row(
                                    children: [
                                      Text(
                                        IconMapper.getIcon(category.icon ?? ''),
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          category.name,
                                          style: Theme.of(context).textTheme.titleSmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        _getChangeIcon(category.percentageChange),
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Período 1
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'P1: ${_formatCurrency(category.amountPeriodOne)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        '(${category.countPeriodOne})',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Período 2
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'P2: ${_formatCurrency(category.amountPeriodTwo)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        '(${category.countPeriodTwo})',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Divider(height: 12),

                                  // Diferencia
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Cambio: ${_formatCurrency(category.difference)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _getChangeColor(category.percentageChange),
                                        ),
                                      ),
                                      Text(
                                        '${category.percentageChange.toStringAsFixed(1)}%',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _getChangeColor(category.percentageChange),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ] else
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Sin datos en las categorías',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Sin datos para comparar',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
