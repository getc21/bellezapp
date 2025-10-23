import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

class ReportPage extends StatefulWidget {
  @override
  ReportPageState createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _weeklyRotationProducts = [];
  List<Map<String, dynamic>> _monthlyRotationProducts = [];
  List<Map<String, dynamic>> _yearlyRotationProducts = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final weeklyRotationProducts = await dbHelper.getProductsByRotation(period: 'week');
    final monthlyRotationProducts = await dbHelper.getProductsByRotation(period: 'month');
    final yearlyRotationProducts = await dbHelper.getProductsByRotation(period: 'year');
    setState(() {
      _weeklyRotationProducts = weeklyRotationProducts;
      _monthlyRotationProducts = monthlyRotationProducts;
      _yearlyRotationProducts = yearlyRotationProducts;
    });
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Reporte de Productos con Mayor y Menor Rotación', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Rotación de Productos en la Última Semana', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                headers: ['ID', 'Nombre', 'Cantidad Vendida'],
                data: _weeklyRotationProducts.map((product) => [product['id'], product['name'], product['total_quantity']]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Rotación de Productos en los Últimos 30 Días', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                headers: ['ID', 'Nombre', 'Cantidad Vendida'],
                data: _monthlyRotationProducts.map((product) => [product['id'], product['name'], product['total_quantity']]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Rotación de Productos en el Último Año', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                headers: ['ID', 'Nombre', 'Cantidad Vendida'],
                data: _yearlyRotationProducts.map((product) => [product['id'], product['name'], product['total_quantity']]).toList(),
              ),
            ],
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/reporte_rotacion_productos.pdf");
    await file.writeAsBytes(await pdf.save());

    OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Utils.colorGnav,
        title: Text('Reporte de Rotación de Productos'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
          ),
        ],
      ),
      body: _weeklyRotationProducts.isEmpty && _monthlyRotationProducts.isEmpty && _yearlyRotationProducts.isEmpty
          ? Center(child: Text('No hay datos para el reporte'))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rotación de Productos en la Última Semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.defaultColor)),
                  Center(
                    child: Container(
                      color: Colors.white,
                      child: DataTable(
                        headingRowHeight: 30,
                        dataRowHeight: 30,
                        border: TableBorder(horizontalInside: BorderSide(color: Utils.defaultColor)),
                        columns: [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Unid. Ult. Semana')),
                        ],
                        rows: _weeklyRotationProducts.map((product) {
                          return DataRow(cells: [
                            DataCell(Center(child: Text(product['id'].toString()))),
                            DataCell(Center(child: Text(product['name']))),
                            DataCell(Center(child: Text(product['total_quantity'].toString()))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Rotación de Productos en los Últimos 30 Días', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.defaultColor)),
                  Center(
                    child: Container(
                      color: Colors.white,
                      child: DataTable(
                        headingRowHeight: 30,
                        dataRowHeight: 30,
                        border: TableBorder(horizontalInside: BorderSide(color: Utils.defaultColor)),
                        columns: [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Unid. Ult. 30 días')),
                        ],
                        rows: _monthlyRotationProducts.map((product) {
                          return DataRow(cells: [
                            DataCell(Center(child: Text(product['id'].toString()))),
                            DataCell(Center(child: Text(product['name']))),
                            DataCell(Center(child: Text(product['total_quantity'].toString()))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Rotación de Productos en el Último Año', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.defaultColor)),
                  Center(
                    child: Container(
                      color: Colors.white,
                      child: DataTable(
                        headingRowHeight: 30,
                        dataRowHeight: 30,
                        border: TableBorder(horizontalInside: BorderSide(color: Utils.defaultColor)),
                        columns: [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Unid. Ult. Año')),
                        ],
                        rows: _yearlyRotationProducts.map((product) {
                          return DataRow(cells: [
                            DataCell(Center(child: Text(product['id'].toString()))),
                            DataCell(Center(child: Text(product['name']))),
                            DataCell(Center(child: Text(product['total_quantity'].toString()))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}