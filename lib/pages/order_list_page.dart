import 'dart:developer';

import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/pages/add_order_page.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderListPage extends StatefulWidget {
  @override
  OrderListPageState createState() => OrderListPageState();
}

class OrderListPageState extends State<OrderListPage> {
  final dbHelper = DatabaseHelper();
  final themeController = Get.find<ThemeController>();
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final orders = await dbHelper.getOrdersWithItems();
    log(orders.toString());
    setState(() {
      // Ordenar las órdenes de la última a la primera
      _orders = orders.reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: Utils.colorFondo,
      body: _orders.isEmpty
          ? Center(child: Text('No hay órdenes disponibles'))
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final orderDate = DateFormat('yyyy-MM-dd')
                    .format(DateTime.parse(order['order_date']));
                return Card(
                  color: Utils.colorFondoCards,
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden: ${order['id']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Utils.textLlaveValor('Fecha: ', orderDate),
                        SizedBox(height: 10),
                        Text(
                          'Productos de la orden:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 30,
                            dataRowHeight: 30,
                            columns: [
                              DataColumn(label: Text('Cantidad')),
                              DataColumn(label: Text('Producto')),
                              DataColumn(label: Text('Precio')),
                            ],
                            rows: order['items'].map<DataRow>((item) {
                              return DataRow(cells: [
                                DataCell(Text('${item['quantity']} Unid.')),
                                DataCell(Text(item['product_name'])),
                                DataCell(Text('\Bs${item['price']}')),
                              ]);
                            }).toList(),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Utils.bigTextLlaveValor('Total: ', 'Bs. ${order['totalOrden']}')
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () {
          Get.to(AddOrderPage());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    )); // Cerrar Obx
  }
}