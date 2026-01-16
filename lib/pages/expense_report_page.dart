import 'package:bellezapp/controllers/indexpage_controller.dart';
import 'package:bellezapp/controllers/store_controller.dart';
import 'package:bellezapp/controllers/expense_controller.dart';
import 'package:bellezapp/pages/add_expense_page.dart';
import 'package:bellezapp/utils/icon_mapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExpenseReportPage extends StatefulWidget {
  const ExpenseReportPage({super.key});

  @override
  ExpenseReportPageState createState() => ExpenseReportPageState();
}

class ExpenseReportPageState extends State<ExpenseReportPage> {
  final ipc = Get.find<IndexPageController>();
  final storeController = Get.find<StoreController>();
  final expenseController = Get.find<ExpenseController>();

  String _selectedPeriod = 'monthly';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
    
    // 🔴 Observar cambios de tienda para recargar el reporte
    ever<Map<String, dynamic>?>(storeController.currentStoreRx, (store) {
      if (store != null) {
        _loadReport();
      }
    });
  }

  Future<void> _loadReport() async {
    final currentStore = storeController.currentStore;
    if (currentStore != null) {
      if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
        await expenseController.loadExpenseReport(
          storeId: currentStore['_id'],
          period: 'custom',
          startDate: _customStartDate,
          endDate: _customEndDate,
        );
      } else {
        await expenseController.loadExpenseReport(
          storeId: currentStore['_id'],
          period: _selectedPeriod,
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final currentStore = storeController.currentStore;
    if (currentStore == null) return;

    final ctx = context; // Capture context before async operation

    final pickedRange = await showDateRangePicker(
      context: ctx,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (pickedRange != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _customStartDate = pickedRange.start;
        _customEndDate = pickedRange.end;
      });
      await _loadReport();
    }
  }

  Future<void> _generateExpensePDF() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final ctx = context; // Capture context before async operations
    
    debugPrint('🔴 [PDF] Iniciando generación de PDF');
    
    // Solicita fecha de inicio
    final startDatePicker = await showDatePicker(
      context: ctx,
      initialDate: firstDayOfMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (startDatePicker == null) {
      debugPrint('🔴 [PDF] Usuario canceló selección de fecha inicial');
      return;
    }
    debugPrint('🟡 [PDF] Fecha inicial seleccionada: $startDatePicker');

    // Solicita fecha de fin
    final endDatePicker = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: startDatePicker,
      lastDate: DateTime.now(),
    );

    if (endDatePicker == null) {
      debugPrint('🔴 [PDF] Usuario canceló selección de fecha final');
      return;
    }
    debugPrint('🟡 [PDF] Fecha final seleccionada: $endDatePicker');

    final currentStore = storeController.currentStore;
    if (currentStore == null) {
      debugPrint('🔴 [PDF] No hay tienda seleccionada');
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una tienda')),
      );
      return;
    }
    debugPrint('🟡 [PDF] Tienda seleccionada: ${currentStore['name']}');

    // Mostrar loading
    if (!mounted) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      debugPrint('🟡 [PDF] Cargando reporte de gastos...');
      // Cargar gastos para el rango de fechas
      await expenseController.loadExpenseReport(
        storeId: currentStore['_id'],
        period: 'custom',
        startDate: startDatePicker,
        endDate: endDatePicker.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
      );

      final report = expenseController.report;
      debugPrint('🟡 [PDF] Reporte cargado. Null: ${report == null}');
      
      if (report != null) {
        debugPrint('✅ [PDF] Datos del reporte:');
        debugPrint('   - Total: \$${report.totalExpense}');
        debugPrint('   - Transacciones: ${report.expenseCount}');
        debugPrint('   - Categorías: ${report.byCategory.length}');
        debugPrint('   - Top gastos: ${report.topExpenses.length}');
      } else {
        debugPrint('🔴 [PDF] El reporte es null');
      }
      
      if (!mounted) return;
      Navigator.pop(ctx); // Cerrar loading dialog

      if (report != null && report.byCategory.isNotEmpty) {
        debugPrint('✅ [PDF] Iniciando creación del PDF...');
        await _createAndPrintPDF(report, startDatePicker, endDatePicker, currentStore);
        debugPrint('✅ [PDF] PDF creado exitosamente');
      } else {
        if (!mounted) return;
        final errorMsg = report == null 
            ? 'El reporte es null' 
            : 'No hay categorías en el reporte (${report.byCategory.length} categorías)';
        debugPrint('🔴 [PDF] Error: $errorMsg');
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('No hay datos de gastos para el período seleccionado')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [PDF] ERROR CAPTURADO:');
      debugPrint('   Tipo: ${e.runtimeType}');
      debugPrint('   Mensaje: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (!mounted) return;
      Navigator.pop(ctx); // Cerrar loading dialog
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _createAndPrintPDF(
    dynamic report,
    DateTime startDate,
    DateTime endDate,
    Map<String, dynamic> store,
  ) async {
    try {
      debugPrint('🟡 [PDF] Creando documento PDF...');
      final pdf = pw.Document();
      debugPrint('🟡 [PDF] Documento creado');

      debugPrint('🟡 [PDF] Agregando página...');
      pdf.addPage(
        pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => [
          // Encabezado
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'REPORTE DE GASTOS',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                store['name'] ?? 'Tienda',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Container(
                margin: pw.EdgeInsets.symmetric(vertical: 16),
                child: pw.Divider(),
              ),
            ],
          ),

          // Período
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Período:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Fecha de Generación:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Resumen
          pw.Container(
            padding: pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RESUMEN',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Gastos:'),
                        pw.Text(
                          '\$${report.totalExpense.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Número de Transacciones:'),
                        pw.Text(
                          '${report.expenseCount}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Promedio por Gasto:'),
                        pw.Text(
                          '\$${report.averageExpense.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Desglose por categoría
          if (report.byCategory.isNotEmpty) ...[
            pw.Text(
              'DESGLOSE POR CATEGORÍA',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const ['Categoría', 'Total', 'Transacciones', 'Porcentaje'],
              data: _buildCategoryTableData(report),
              cellHeight: 30,
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 24),
          ],

          // Top 10 gastos
          if (report.topExpenses.isNotEmpty) ...[
            pw.Text(
              'PRINCIPALES GASTOS',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const ['Fecha', 'Descripción', 'Monto'],
              data: _buildExpensesTableData(report),
              cellHeight: 30,
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 40),
          ],

          // Pie de página
          pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Documento generado automáticamente por Bellezapp',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
      );
      debugPrint('🟡 [PDF] Página agregada al documento');

      debugPrint('🟡 [PDF] Generando PDF...');
      // Generar y mostrar el PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Reporte_Gastos_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
      debugPrint('✅ [PDF] PDF generado y mostrado exitosamente');
    } catch (e, stackTrace) {
      debugPrint('🔴 [PDF] ERROR en _createAndPrintPDF:');
      debugPrint('   Tipo: ${e.runtimeType}');
      debugPrint('   Mensaje: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Gastos'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generateExpensePDF,
            tooltip: 'Generar PDF',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.to(() => const AddExpensePage());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReport,
        child: Obx(
          () => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de período
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Período',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildPeriodButton('Hoy', 'daily'),
                              const SizedBox(width: 8),
                              _buildPeriodButton('Esta semana', 'weekly'),
                              const SizedBox(width: 8),
                              _buildPeriodButton('Este mes', 'monthly'),
                              const SizedBox(width: 8),
                              _buildPeriodButton('Este año', 'yearly'),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _selectDateRange,
                                icon: const Icon(Icons.calendar_today),
                                label: const Text('Personalizado'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Del ${_customStartDate!.day}/${_customStartDate!.month}/${_customStartDate!.year} al ${_customEndDate!.day}/${_customEndDate!.month}/${_customEndDate!.year}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Resumen
                if (expenseController.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (expenseController.report != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total de Gastos',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${expenseController.report!.totalExpense.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Transacciones',
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                      Text(
                                        '${expenseController.report!.expenseCount}',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Promedio',
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                      Text(
                                        '\$${expenseController.report!.averageExpense.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Por categoría
                      Text(
                        'Gastos por Categoría',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...expenseController.report!.byCategory.map((category) {
                        final percentage = expenseController.report!.totalExpense > 0
                            ? (category.total / expenseController.report!.totalExpense) * 100
                            : 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Text(
                                              IconMapper.getIcon(category.icon),
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              category.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${category.total.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          minHeight: 6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${category.count} transacciones',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),

                      // Top gastos
                      Text(
                        'Gastos Principales',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...expenseController.report!.topExpenses.take(10).map((expense) {
                        return ListTile(
                          leading: const Icon(
                            Icons.receipt,
                            color: Colors.amber,
                          ),
                          title: Text(expense.description ?? 'Sin descripción'),
                          subtitle: Text(
                            '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                          ),
                          trailing: Text(
                            '\$${expense.amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        );
                      }),
                    ],
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.trending_down,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sin gastos registrados',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              Get.to(() => const AddExpensePage());
                            },
                            child: const Text('Registrar Gasto'),
                          ),
                        ],
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

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return OutlinedButton(
      onPressed: () {
        setState(() => _selectedPeriod = period);
        _loadReport();
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : null,
        ),
      ),
    );
  }

  // Helper para construir datos de tabla de categorías
  List<List<String>> _buildCategoryTableData(dynamic report) {
    return (report.byCategory as List<dynamic>)
        .map<List<String>>((dynamic cat) => [
          (cat.name as String?) ?? '',
          '\$${(cat.total as num).toStringAsFixed(2)}',
          '${cat.count}',
          '${((cat.total as num) / (report.totalExpense as num) * 100).toStringAsFixed(1)}%',
        ])
        .toList();
  }

  // Helper para construir datos de tabla de gastos
  List<List<String>> _buildExpensesTableData(dynamic report) {
    return (report.topExpenses as List<dynamic>)
        .take(10)
        .map<List<String>>((dynamic exp) => [
          DateFormat('dd/MM/yyyy').format(exp.date as DateTime),
          (exp.description as String?) ?? 'Sin descripción',
          '\$${(exp.amount as num).toStringAsFixed(2)}',
        ])
        .toList();
  }
}
