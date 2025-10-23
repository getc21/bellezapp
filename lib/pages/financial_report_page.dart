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
                                  dialogBackgroundColor: Utils.colorFondo,
                                  primaryColor: Utils.colorBotones,
                                  colorScheme: ColorScheme.light(
                                      primary: Utils.colorBotones,
                                      secondary: Utils.colorGnav),
                                  
                                  buttonTheme: ButtonThemeData(
                                    textTheme: ButtonTextTheme.primary,
                                  ),
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
                                  dialogBackgroundColor: Utils.colorFondo,
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
                                  ),
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
        title: Text('Reporte Financiero Mensual'),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _generateAndShowPdf,
          ),
        ],
      ),
      body: _financialData.isEmpty
          ? Center(child: Text('No hay datos financieros disponibles'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowHeight: 30,
                        dataRowHeight: 30,
                        columns: [
                          DataColumn(label: Text('Mes')),
                          DataColumn(label: Text('Año')),
                          DataColumn(label: Text('Entradas')),
                          DataColumn(label: Text('Salidas')),
                          DataColumn(label: Text('Balance')),
                        ],
                        rows: _financialData.map((data) {
                          return DataRow(cells: [
                            DataCell(Text(data['month'])),
                            DataCell(Text(data['year'])),
                            DataCell(Text(data['totalIncome'].toString())),
                            DataCell(Text(data['totalExpense'].toString())),
                            DataCell(Text(
                                (data['totalIncome'] - data['totalExpense'])
                                    .toString())),
                          ]);
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20),
                    Utils.elevatedButton('Ver Gráfico', Utils.colorBotones, _navigateToChartPage),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: _showDateRangeDialog,
        child: Icon(Icons.date_range, color: Colors.white),
      ),
    );
  }
}