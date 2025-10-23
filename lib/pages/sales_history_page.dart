import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SalesHistoryPage extends StatefulWidget {
  @override
  SalesHistoryPageState createState() => SalesHistoryPageState();
}

class SalesHistoryPageState extends State<SalesHistoryPage> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _salesData = [];

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    final salesData = await dbHelper.getSalesDataForLastYear();
    setState(() {
      _salesData = salesData;
    });
  }

  Future<void> _generateAndShowPdf() async {
    final pdf = pw.Document();

    for (var monthData in _salesData) {
      final month = monthData['month'];
      final year = monthData['year'];
      final totalProfit = monthData['totalProfit'];
      final totalCost = monthData['totalCost'];
      final products = monthData['products'];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Mes: $month/$year',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.Text(
                    'Total de Utilidad: \$${totalProfit.toStringAsFixed(2)}'),
                pw.Text('Costo Total: \$${totalCost.toStringAsFixed(2)}'),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Productos Vendidos:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.Table.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>[
                      'Producto',
                      'Precio de Compra',
                      'Precio de Venta',
                      'Cantidad Vendida',
                      'Utilidad'
                    ],
                    ...products
                        .map((product) => [
                              product['name'].toString(),
                              '\$${product['purchase_price'].toString()}',
                              '\$${product['sale_price'].toString()}',
                              product['quantity'].toString(),
                              '\$${product['profit'].toString()}',
                            ])
                        .toList()
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/sales_history.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: Text('Historial de Ventas'),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _generateAndShowPdf,
          ),
        ],
      ),
      body: _salesData.isEmpty
          ? Center(child: Text('No hay datos de ventas disponibles'))
          : ListView.builder(
              itemCount: _salesData.length,
              itemBuilder: (context, index) {
                final monthData = _salesData[index];
                final month = monthData['month'];
                final year = monthData['year'];
                final totalProfit = monthData['totalProfit'];
                final totalCost = monthData['totalCost'];
                final products = monthData['products'];

                return Card(
                  color: Utils.colorFondoCards,
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mes: $month/$year',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Utils.defaultColor),
                        ),
                        Utils.textLlaveValor('Costo Total: ',
                            'Bs. ${totalCost.toStringAsFixed(2)}'),
                        Utils.espacio20,
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Utils.bigTextLlaveValor('Total de Utilidad: ',
                                  'Bs.${totalProfit.toStringAsFixed(2)}'),
                            ]),
                        SizedBox(height: 10),
                        Text(
                          'Productos Vendidos:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Utils.defaultColor),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            color: Colors.white,
                            child: DataTable(
                              dataRowHeight: 30,
                              columnSpacing: 15,
                              horizontalMargin: 10,
                              headingRowHeight: 80,
                              columns: [
                                DataColumn(label: Text('Producto')),
                                DataColumn(
                                    label: Text('Precio\nde\nCompra',
                                        textAlign: TextAlign.center)),
                                DataColumn(
                                    label: Text('Precio\nde\nVenta',
                                        textAlign: TextAlign.center)),
                                DataColumn(
                                    label: Text('Cantidad\nVendida',
                                        textAlign: TextAlign.center)),
                                DataColumn(
                                    label: Text('Utilidad',
                                        textAlign: TextAlign.center)),
                              ],
                              rows: products.map<DataRow>((product) {
                                return DataRow(
                                  cells: [
                                    DataCell(Center(
                                        child:
                                            Text(product['name'].toString()))),
                                    DataCell(Center(
                                        child: Text(
                                            product['purchase_price'].toString()))),
                                    DataCell(Center(
                                        child: Text(
                                            product['sale_price'].toString()))),
                                    DataCell(Center(
                                        child: Text(
                                            product['quantity'].toString()))),
                                    DataCell(Center(
                                        child: Text(
                                            product['profit'].toString()))),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
