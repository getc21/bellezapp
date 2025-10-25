import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

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

  // Empty State profesional
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Utils.colorFondo,
            Utils.colorFondo.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Utils.colorGnav.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.trending_up_outlined,
              size: 64,
              color: Utils.colorGnav,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Sin Historial de Ventas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Utils.colorTexto,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Aún no hay datos de ventas registrados.\nComienza a registrar ventas para ver tu historial financiero.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Utils.colorTexto.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadSalesData,
            icon: Icon(Icons.refresh_outlined),
            label: Text('Actualizar Datos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Utils.colorBotones,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dashboard financiero superior
  Widget _buildFinancialDashboard() {
    if (_salesData.isEmpty) return SizedBox.shrink();

    double totalRevenue = _salesData.fold(0.0, (sum, month) {
      final profit = month['totalProfit'] is double ? month['totalProfit'] : double.tryParse(month['totalProfit'].toString()) ?? 0.0;
      return sum + profit;
    });
    
    double totalCosts = _salesData.fold(0.0, (sum, month) {
      final cost = month['totalCost'] is double ? month['totalCost'] : double.tryParse(month['totalCost'].toString()) ?? 0.0;
      return sum + cost;
    });
    
    double profitMargin = totalCosts > 0 ? (totalRevenue / totalCosts) * 100 : 0;
    int totalMonths = _salesData.length;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Utils.colorGnav.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard_outlined,
                  color: Utils.colorGnav,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Financiero',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Utils.colorTexto,
                      ),
                    ),
                    Text(
                      'Resumen del último año',
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
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Ingresos Totales',
                  'Bs. ${totalRevenue.toStringAsFixed(2)}',
                  Icons.trending_up_outlined,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  'Costos Totales',
                  'Bs. ${totalCosts.toStringAsFixed(2)}',
                  Icons.trending_down_outlined,
                  Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Margen de Ganancia',
                  '${profitMargin.toStringAsFixed(1)}%',
                  Icons.percent_outlined,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  'Períodos',
                  '$totalMonths meses',
                  Icons.calendar_month_outlined,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card de KPI individual
  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icono a la izquierda
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          // Texto a la derecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Utils.colorTexto,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Utils.colorTexto.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card moderno de ventas mensuales
  Widget _buildModernSalesCard(Map<String, dynamic> monthData, int index) {
    final month = monthData['month'] is int ? monthData['month'] : int.tryParse(monthData['month'].toString()) ?? 1;
    final year = monthData['year'] is int ? monthData['year'] : int.tryParse(monthData['year'].toString()) ?? DateTime.now().year;
    final totalProfit = (monthData['totalProfit'] is double) ? monthData['totalProfit'] : double.tryParse(monthData['totalProfit'].toString()) ?? 0.0;
    final totalCost = (monthData['totalCost'] is double) ? monthData['totalCost'] : double.tryParse(monthData['totalCost'].toString()) ?? 0.0;
    final products = monthData['products'] ?? [];
    final margin = totalCost > 0 ? ((totalProfit / totalCost) * 100) : 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del mes
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Utils.colorGnav.withOpacity(0.1),
                  Utils.colorBotones.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Utils.colorGnav.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: Utils.colorGnav,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMonthName(month) + ' $year',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Utils.colorTexto,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${products.length} productos vendidos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Utils.colorTexto.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: margin > 50 ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${margin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: margin > 50 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Métricas financieras
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildFinancialMetric(
                    'Costo Total',
                    'Bs. ${totalCost.toStringAsFixed(2)}',
                    Icons.trending_down_outlined,
                    Colors.red,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildFinancialMetric(
                    'Utilidad Total',
                    'Bs. ${totalProfit.toStringAsFixed(2)}',
                    Icons.trending_up_outlined,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Lista de productos
          if (products.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Utils.colorGnav,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Productos Vendidos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Utils.colorTexto,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            ...products.take(3).map((product) => _buildProductTile(product)).toList(),
            if (products.length > 3)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      _showAllProducts(context, products, _getMonthName(month), year);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Utils.colorGnav.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Utils.colorGnav.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.expand_more_outlined,
                            color: Utils.colorGnav,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '+ ${products.length - 3} productos más',
                            style: TextStyle(
                              color: Utils.colorGnav,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
          SizedBox(height: 8),
        ],
      ),
    );
  }

  // Métrica financiera individual
  Widget _buildFinancialMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Utils.colorTexto,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Utils.colorTexto.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Tile de producto individual
  Widget _buildProductTile(Map<String, dynamic> product) {
    final profit = product['profit'] is double ? product['profit'] : double.tryParse(product['profit'].toString()) ?? 0.0;
    final quantity = product['quantity'] is int ? product['quantity'] : int.tryParse(product['quantity'].toString()) ?? 0;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Utils.colorFondo.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Utils.colorGnav.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_outlined,
              color: Utils.colorGnav,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'].toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Utils.colorTexto,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Cantidad: $quantity',
                  style: TextStyle(
                    fontSize: 12,
                    color: Utils.colorTexto.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: profit > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Bs. ${profit.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: profit > 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar todos los productos en un modal
  void _showAllProducts(BuildContext context, List<dynamic> products, String monthName, int year) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header del modal
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Utils.colorGnav.withOpacity(0.1),
                    Utils.colorBotones.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Barra de arrastre
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Utils.colorGnav.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: Utils.colorGnav,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Productos Vendidos',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Utils.colorTexto,
                              ),
                            ),
                            Text(
                              '$monthName $year • ${products.length} productos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Utils.colorTexto.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Utils.colorTexto,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Lista de productos
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildExpandedProductTile(product, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tile expandido de producto para el modal
  Widget _buildExpandedProductTile(Map<String, dynamic> product, int index) {
    final profit = product['profit'] is double ? product['profit'] : double.tryParse(product['profit'].toString()) ?? 0.0;
    final quantity = product['quantity'] is int ? product['quantity'] : int.tryParse(product['quantity'].toString()) ?? 0;
    final purchasePrice = product['purchase_price'] is double ? product['purchase_price'] : double.tryParse(product['purchase_price'].toString()) ?? 0.0;
    final salePrice = product['sale_price'] is double ? product['sale_price'] : double.tryParse(product['sale_price'].toString()) ?? 0.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Utils.colorGnav.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Número de producto
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Utils.colorGnav.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Utils.colorGnav,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Utils.colorTexto,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cantidad vendida: $quantity',
                      style: TextStyle(
                        fontSize: 14,
                        color: Utils.colorTexto.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Badge de utilidad
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: profit > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bs. ${profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: profit > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Detalles financieros
          Row(
            children: [
              Expanded(
                child: _buildPriceDetail(
                  'Compra',
                  'Bs. ${purchasePrice.toStringAsFixed(2)}',
                  Icons.shopping_cart_outlined,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildPriceDetail(
                  'Venta',
                  'Bs. ${salePrice.toStringAsFixed(2)}',
                  Icons.sell_outlined,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget para mostrar detalles de precio
  Widget _buildPriceDetail(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Utils.colorTexto.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Utils.colorTexto,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper para nombres de meses
  String _getMonthName(int month) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return month > 0 && month < months.length ? months[month] : 'Mes $month';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Utils.colorGnav,
                Utils.colorBotones,
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.monetization_on_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Historial de Ventas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Análisis Financiero',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _generateAndShowPdf,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _salesData.isEmpty
          ? _buildEmptyState()
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Utils.colorFondo,
                    Utils.colorFondo.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Dashboard financiero superior
                  _buildFinancialDashboard(),
                  
                  // Lista de ventas mensuales
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _salesData.length,
                      itemBuilder: (context, index) {
                        final monthData = _salesData[index];
                        return _buildModernSalesCard(monthData, index);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
