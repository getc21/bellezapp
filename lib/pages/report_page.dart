import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

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

  // Empty State profesional
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
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
              Icons.insert_chart_outlined,
              size: 64,
              color: Utils.colorGnav,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Sin Datos de Rotación',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Utils.colorTexto,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'No hay información suficiente para generar el reporte.\nRegistra algunas ventas para ver los análisis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Utils.colorTexto.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadReportData,
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

  // Dashboard de métricas principales
  Widget _buildMetricsDashboard() {
    int totalWeekly = _weeklyRotationProducts.fold(0, (sum, product) => sum + (product['total_quantity'] as int));
    int totalMonthly = _monthlyRotationProducts.fold(0, (sum, product) => sum + (product['total_quantity'] as int));
    int totalYearly = _yearlyRotationProducts.fold(0, (sum, product) => sum + (product['total_quantity'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen Ejecutivo',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Utils.colorTexto,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Ventas Semanales', totalWeekly.toString(), Icons.trending_up_outlined, Colors.blue)),
            SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Ventas Mensuales', totalMonthly.toString(), Icons.bar_chart_outlined, Colors.green)),
            SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Ventas Anuales', totalYearly.toString(), Icons.show_chart_outlined, Colors.orange)),
          ],
        ),
      ],
    );
  }

  // Card de métrica individual
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
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
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Sección de rotación moderna
  Widget _buildRotationSection(String title, String subtitle, List<Map<String, dynamic>> products, IconData icon, Color color) {
    return Container(
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
          // Header de la sección
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
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
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Utils.colorTexto,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
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
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${products.length} productos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de productos
          if (products.isNotEmpty) 
            ...products.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> product = entry.value;
              bool isLast = index == products.length - 1;
              
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: !isLast ? Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ) : null,
                ),
                child: Row(
                  children: [
                    // Ranking badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getRankingColor(index).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getRankingColor(index),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // Información del producto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Utils.colorTexto,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ID: ${product['id']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Utils.colorTexto.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Cantidad vendida
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up_outlined,
                            size: 16,
                            color: color,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${product['total_quantity']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()
          else
            Container(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Sin datos para este período',
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper para colores de ranking
  Color _getRankingColor(int index) {
    switch (index) {
      case 0: return Colors.amber; // Oro
      case 1: return Colors.grey; // Plata
      case 2: return Colors.brown; // Bronce
      default: return Utils.colorGnav;
    }
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
                Icons.analytics_outlined,
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
                    'Análisis de Rotación',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Reportes de Productos',
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
                onTap: _generatePdfReport,
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
      body: _weeklyRotationProducts.isEmpty && _monthlyRotationProducts.isEmpty && _yearlyRotationProducts.isEmpty
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard de métricas principales
                    _buildMetricsDashboard(),
                    SizedBox(height: 24),
                    
                    // Rotación Semanal
                    _buildRotationSection(
                      'Rotación Última Semana',
                      'Productos más vendidos en los últimos 7 días',
                      _weeklyRotationProducts,
                      Icons.calendar_view_week_outlined,
                      Colors.blue,
                    ),
                    SizedBox(height: 20),
                    
                    // Rotación Mensual
                    _buildRotationSection(
                      'Rotación Últimos 30 Días',
                      'Tendencias de ventas del mes actual',
                      _monthlyRotationProducts,
                      Icons.calendar_month_outlined,
                      Colors.green,
                    ),
                    SizedBox(height: 20),
                    
                    // Rotación Anual
                    _buildRotationSection(
                      'Rotación Último Año',
                      'Análisis anual de productos estrella',
                      _yearlyRotationProducts,
                      Icons.calendar_today_outlined,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}