import 'dart:developer';

import 'package:bellezapp/controllers/indexpage_controller.dart';
import 'package:bellezapp/pages/home_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:get/get.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  AddOrderPageState createState() => AddOrderPageState();
}

class AddOrderPageState extends State<AddOrderPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  List<Map<String, dynamic>> _products = [];
  final dbHelper = DatabaseHelper();
  final ipc = Get.find<IndexPageController>();
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      final productName = scanData.code;
      final product = await dbHelper.getProductByName(productName!);
      if (product != null) {
        setState(() {
          if (!_products.any((p) => p['id'] == product['id'])) {
            _products.add({
              'id': product['id'],
              'name': product['name'],
              'quantity': 1, // Inicializa la cantidad en 1
              'price': product['sale_price'],
            });
            log('Product added: ${product['name']}');
            FlutterRingtonePlayer().play(
              fromAsset: 'assets/img/beep.mp3',
            );
          }
        });
      }
    });
  }

  void _incrementQuantity(int index) {
    setState(() {
      _products[index]['quantity']++;
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_products[index]['quantity'] > 1) {
        _products[index]['quantity']--;
      }
    });
  }

  void _registerOrder() async {
    if (_products.isEmpty) {
      // Mostrar un mensaje de advertencia si no hay productos en la lista
      Get.snackbar(
        'Advertencia',
        'No se puede registrar una orden sin productos.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final newOrder = {
      'products': _products,
      'date': DateTime.now().toString(),
    };
    await dbHelper.insertOrder(newOrder);

    // Update product stock
    for (var product in _products) {
      await dbHelper.updateProductStock(product['id'], product['quantity']);
    }
    await controller?.pauseCamera();
    ipc.setIndexPage(4);
    Get.to(() => HomePage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: Text('Agregar Orden'),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ListTile(
                      title: Text(product['name']),
                      subtitle: Text('Cantidad: ${product['quantity']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => _decrementQuantity(index),
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(), // Hace el botón redondo
                              backgroundColor: Utils.colorBotones,// Fondo rojo
                              padding: EdgeInsets.all(
                                  10), // Ajusta el tamaño del botón
                            ),
                            child: Icon(Icons.remove,
                                color: Colors.white), // Ícono blanco
                          ),
                          Text('${product['quantity']}', style: TextStyle(fontSize: 14)),
                          ElevatedButton(
                            onPressed: () => _incrementQuantity(index),
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(), // Hace el botón redondo
                              backgroundColor: Utils.colorBotones, // Fondo rojo
                              padding: EdgeInsets.all(
                                  10), // Ajusta el tamaño del botón
                            ),
                            child: Icon(Icons.add,
                                color: Colors.white), // Ícono blanco
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Utils.elevatedButton('Registrar Orden', Utils.colorBotones, () {
            _registerOrder();
          }),
          Utils.espacio20
        ],
      ),
    );
  }
}
