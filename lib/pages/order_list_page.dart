import 'dart:developer';

import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/mixins/store_aware_mixin.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/pages/add_order_page.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  OrderListPageState createState() => OrderListPageState();
}

class OrderListPageState extends State<OrderListPage> with StoreAwareMixin {
  final dbHelper = DatabaseHelper();
  final themeController = Get.find<ThemeController>();
  final RxList<Map<String, dynamic>> _orders = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _filteredOrders = <Map<String, dynamic>>[].obs;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void reloadData() {
    print('🔄 Recargando órdenes por cambio de tienda');
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final orders = await dbHelper.getOrdersWithItems();
    log(orders.toString());
    // Ordenar las órdenes de la última a la primera
    final sortedOrders = orders.reversed.toList();
    _orders.value = sortedOrders;
    _filteredOrders.value = sortedOrders;
  }

  void _filterOrders(String searchText) {
    if (searchText.isEmpty) {
      _filteredOrders.value = List.from(_orders);
    } else {
      _filteredOrders.value = _orders.where((order) {
        final orderId = order['id'].toString();
        final orderDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(order['order_date']));
        final total = order['totalOrden'].toString();
        final searchLower = searchText.toLowerCase();
        
        // Buscar también en los nombres de productos
        bool hasProductMatch = false;
        if (order['items'] != null) {
          hasProductMatch = order['items'].any((item) =>
              (item['product_name'] ?? '').toString().toLowerCase().contains(searchLower));
        }
        
        return orderId.contains(searchLower) ||
               orderDate.contains(searchLower) ||
               total.contains(searchLower) ||
               hasProductMatch;
      }).toList();
    }
  }

  // Método público para refrescar la lista desde fuera
  Future<void> refreshOrders() async {
    await _loadOrders();
  }

  String _formatCurrency(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0.0;
    return 'Bs. ${amount.toStringAsFixed(2)}';
  }

  Widget _buildEmptyState() {
    String mensaje;
    
    if (_searchController.text.isNotEmpty) {
      mensaje = 'No se encontraron órdenes que coincidan con tu búsqueda.';
    } else {
      mensaje = 'No hay órdenes registradas en esta tienda. Agrega tu primera orden usando el botón "+".';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Utils.colorBotones.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Utils.colorBotones,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin Órdenes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Utils.colorTexto,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Utils.colorTexto.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _loadOrders();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Utils.colorBotones,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTable(List<dynamic> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DataTable(
        headingRowHeight: 36,
        dataRowHeight: 32,
        horizontalMargin: 12,
        columnSpacing: 8,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Utils.colorGnav,
        ),
        dataTextStyle: TextStyle(
          fontSize: 11,
          color: Colors.grey[700],
        ),
        columns: [
          DataColumn(
            label: Expanded(
              flex: 1,
              child: Text('Cant.', textAlign: TextAlign.center),
            ),
          ),
          DataColumn(
            label: Expanded(
              flex: 3,
              child: Text('Producto'),
            ),
          ),
          DataColumn(
            label: Expanded(
              flex: 2,
              child: Text('Precio', textAlign: TextAlign.end),
            ),
          ),
        ],
        rows: items.map<DataRow>((item) {
          return DataRow(cells: [
            DataCell(
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Utils.colorBotones.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item['quantity']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Utils.colorBotones,
                    ),
                  ),
                ),
              ),
            ),
            DataCell(
              Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: Text(
                  item['product_name'] ?? 'Sin nombre',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            DataCell(
              Container(
                width: double.infinity,
                alignment: Alignment.centerRight,
                child: Text(
                  _formatCurrency(item['price']),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Utils.colorTexto,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: Utils.colorFondo,
      body: Column(
        children: [
          // Header moderno con búsqueda
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo de búsqueda prominente
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterOrders,
                    style: TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar órdenes...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: Utils.colorBotones, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _filterOrders('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Header con contador y resumen
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Órdenes de Venta',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Utils.colorBotones.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_filteredOrders.length} órdenes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Utils.colorBotones,
                            ),
                          ),
                        ),
                        if (_filteredOrders.isNotEmpty) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Utils.colorBotones.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatCurrency(_filteredOrders.fold(0.0, (sum, order) => 
                                sum + (double.tryParse(order['totalOrden'].toString()) ?? 0.0))),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Utils.colorBotones,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 6),
              ],
            ),
          ),
          // Lista de órdenes
          Expanded(
            child: _filteredOrders.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        final orderDate = DateFormat('dd/MM/yyyy')
                            .format(DateTime.parse(order['order_date']));
                        final orderTime = DateFormat('HH:mm')
                            .format(DateTime.parse(order['order_date']));
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Utils.colorFondoCards,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header de la orden
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Utils.colorBotones.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Icon(
                                        Icons.receipt_long,
                                        color: Utils.colorBotones,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Orden #${order['id']}',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Utils.colorGnav,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Utils.colorBotones.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'COMPLETADA',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Utils.colorBotones,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                              SizedBox(width: 4),
                                              Text(
                                                orderDate,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                              SizedBox(width: 4),
                                              Text(
                                                orderTime,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                // Productos de la orden
                                Text(
                                  'Productos (${order['items']?.length ?? 0} artículos)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Utils.colorGnav,
                                  ),
                                ),
                                SizedBox(height: 8),
                                _buildProductsTable(order['items'] ?? []),
                                SizedBox(height: 12),
                                // Total en la esquina inferior derecha
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Utils.colorBotones.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Utils.colorBotones.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'TOTAL: ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Utils.colorTexto,
                                            ),
                                          ),
                                          Text(
                                            _formatCurrency(order['totalOrden']),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Utils.colorBotones,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () async {
          final result = await Get.to(AddOrderPage());
          if (result == true) {
            _loadOrders();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    ));
  }
}