import 'package:bellezapp/pages/financial_chart_group_data.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({super.key});

  @override
  FinancialReportPageState createState() => FinancialReportPageState();
}

class FinancialReportPageState extends State<FinancialReportPage> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _financialData = [];
  DateTime? _startDate;
  DateTime? _endDate;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    final financialData = await dbHelper.getFinancialDataForLastYear();
    setState(() {
      _financialData = financialData;
    });
  }

  Future<void> _loadFinancialDataBetweenDates(
      DateTime startDate, DateTime endDate) async {
    final financialData =
        await dbHelper.getFinancialDataBetweenDates(startDate, endDate);
    setState(() {
      _financialData = financialData;
    });
  }

  Future<void> _generateAndShowPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Reporte Financiero Mensual',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Mes', 'Año', 'Entradas', 'Salidas', 'Balance'],
                  ..._financialData.map((data) => [
                        data['month'],
                        data['year'],
                        data['totalIncome'].toString(),
                        data['totalExpense'].toString(),
                        (data['totalIncome'] - data['totalExpense']).toString(),
                      ])
                ],
              ),
            ],
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/financial_report.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(filePath);
  }

  void _showDateRangeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final startDateController = TextEditingController();
        final endDateController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Utils.colorFondoCards,
              title: Text('Seleccionar Rango de Fechas'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: startDateController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'Fecha de Inicio',
                          hintText: 'YYYY-MM-DD',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la fecha de inicio';
                          }
                          return null;
                        },
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  primaryColor: Utils.colorBotones,
                                  colorScheme: ColorScheme.light(
                                      primary: Utils.colorBotones,
                                      secondary: Utils.colorGnav),
                                  
                                  buttonTheme: ButtonThemeData(
                                    textTheme: ButtonTextTheme.primary,
                                  ), dialogTheme: DialogThemeData(backgroundColor: Utils.colorFondo),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              startDateController.text =
                                  picked.toIso8601String().split('T')[0];
                              _startDate = picked;
                            });
                          }
                        },
                      ),
                      Utils.espacio10,
                      TextFormField(
                        controller: endDateController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'Fecha de Fin',
                          hintText: 'YYYY-MM-DD',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la fecha de fin';
                          }
                          return null;
                        },
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  primaryColor: Utils.colorBotones,
                                  colorScheme: ColorScheme.light(
                                      primary: Utils.colorBotones,
                                      secondary: Utils.colorGnav),
                                  textTheme: TextTheme(
                                    headlineMedium:
                                        TextStyle(color: Utils.colorTexto),
                                    bodyMedium: TextStyle(color: Utils.colorTexto),
                                  ),
                                  buttonTheme: ButtonThemeData(
                                    textTheme: ButtonTextTheme.primary,
                                  ), dialogTheme: DialogThemeData(backgroundColor: Utils.colorFondo),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              endDateController.text =
                                  picked.toIso8601String().split('T')[0];
                              _endDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Utils.elevatedButton('Cancelar', Utils.no, () {
                  Navigator.of(context).pop();
                }),
                Utils.elevatedButton('Verificar', Utils.yes, () {
                  if (formKey.currentState?.validate() ?? false) {
                    _loadFinancialDataBetweenDates(_startDate!, _endDate!);
                    Navigator.of(context).pop();
                  }
                }),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToChartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinancialChartPage(financialData: _financialData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: Text(
          'Reporte Financiero',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.picture_as_pdf, size: 20),
              ),
              onPressed: _generateAndShowPdf,
            ),
          ),
        ],
      ),
      body: _financialData.isEmpty
          ? _buildEmptyState()
          : _buildFinancialContent(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Utils.colorBotones, Utils.colorGnav],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Utils.colorBotones.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _showDateRangeDialog,
          child: Icon(Icons.date_range, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Utils.colorFondoCards,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assessment_outlined,
                  size: 64,
                  color: Utils.colorGnav.withOpacity(0.5),
                ),
                SizedBox(height: 16),
                Text(
                  'No hay datos financieros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Utils.colorTexto,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Los reportes aparecerán aquí cuando\ntengas datos de ventas registrados',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Utils.colorTexto.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFinancialSummary(),
          SizedBox(height: 24),
          _buildQuickActions(),
          SizedBox(height: 24),
          _buildFinancialTable(),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    double totalIncome = 0;
    double totalExpenses = 0;
    double totalBalance = 0;

    for (var data in _financialData) {
      totalIncome += (data['totalIncome'] ?? 0).toDouble();
      totalExpenses += (data['totalExpense'] ?? 0).toDouble();
    }
    totalBalance = totalIncome - totalExpenses;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Utils.colorGnav, Utils.colorBotones],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Utils.colorGnav.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Resumen Financiero',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Ingresos Totales',
                  '\$${totalIncome.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.green.shade300,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Gastos Totales',
                  '\$${totalExpenses.toStringAsFixed(0)}',
                  Icons.trending_down,
                  Colors.orange.shade300,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildSummaryCard(
            'Balance Total',
            '\$${totalBalance.toStringAsFixed(0)}',
            totalBalance >= 0 ? Icons.account_balance_wallet : Icons.warning,
            totalBalance >= 0 ? Colors.blue.shade300 : Colors.red.shade300,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color iconColor, {bool isFullWidth = false}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: isFullWidth 
        ? Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Ver Gráfico',
            'Visualizar tendencias',
            Icons.show_chart,
            Colors.blue,
            _navigateToChartPage,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            'Exportar PDF',
            'Generar reporte',
            Icons.picture_as_pdf,
            Colors.red,
            _generateAndShowPdf,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Utils.colorFondoCards,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Utils.colorTexto,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Utils.colorTexto.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTable() {
    return Container(
      decoration: BoxDecoration(
        color: Utils.colorFondoCards,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: Utils.colorGnav, size: 24),
                SizedBox(width: 12),
                Text(
                  'Detalle Mensual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Utils.colorTexto,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: DataTable(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                columnSpacing: 24,
                headingRowHeight: 50,
                dataRowHeight: 45,
                headingRowColor: MaterialStateProperty.all(Utils.colorGnav.withOpacity(0.1)),
                columns: [
                  DataColumn(
                    label: Text(
                      'Mes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Utils.colorGnav,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Año',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Utils.colorGnav,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Ingresos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Utils.colorGnav,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Gastos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Utils.colorGnav,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Balance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Utils.colorGnav,
                      ),
                    ),
                  ),
                ],
                rows: _financialData.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> data = entry.value;
                  double balance = (data['totalIncome'] ?? 0).toDouble() - (data['totalExpense'] ?? 0).toDouble();
                  
                  return DataRow(
                    color: MaterialStateProperty.all(
                      index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                    ),
                    cells: [
                      DataCell(
                        Text(
                          data['month'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Utils.colorTexto,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          data['year']?.toString() ?? '',
                          style: TextStyle(color: Utils.colorTexto),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '\$${(data['totalIncome'] ?? 0).toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '\$${(data['totalExpense'] ?? 0).toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: balance >= 0 ? Colors.blue.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 14,
                                color: balance >= 0 ? Colors.blue.shade700 : Colors.red.shade700,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '\$${balance.abs().toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: balance >= 0 ? Colors.blue.shade700 : Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}