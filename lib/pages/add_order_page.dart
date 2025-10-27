import 'dart:developer';

import 'package:bellezapp/controllers/indexpage_controller.dart';
import 'package:bellezapp/controllers/cash_controller.dart';
import 'package:bellezapp/controllers/payment_controller.dart';
import 'package:bellezapp/controllers/discount_controller.dart';
import 'package:bellezapp/controllers/customer_controller.dart';
import 'package:bellezapp/models/customer.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/widgets/payment_method_dialog.dart';
import 'package:bellezapp/widgets/discount_selection_dialog.dart';
import 'package:bellezapp/widgets/customer_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:get/get.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  AddOrderPageState createState() => AddOrderPageState();
}

class AddOrderPageState extends State<AddOrderPage> {
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final List<Map<String, dynamic>> _products = [];
  final dbHelper = DatabaseHelper();
  final ipc = Get.find<IndexPageController>();
  late CashController cashController;
  late DiscountController discountController;
  late CustomerController customerController;
  Customer? selectedCustomer;
  
  @override
  void initState() {
    super.initState();
    // Inicializar los controladores de forma segura
    try {
      cashController = Get.find<CashController>();
    } catch (e) {
      print('Error al encontrar CashController en AddOrderPage: $e');
      cashController = Get.put(CashController(), permanent: true);
    }
    
    try {
      discountController = Get.find<DiscountController>();
    } catch (e) {
      print('Error al encontrar DiscountController en AddOrderPage: $e');
      discountController = Get.put(DiscountController(), permanent: true);
    }

    try {
      customerController = Get.find<CustomerController>();
    } catch (e) {
      print('Error al encontrar CustomerController en AddOrderPage: $e');
      customerController = Get.put(CustomerController(), permanent: true);
    }
  }
  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  void _handleBarcodeDetection(BarcodeCapture barcodeCapture) async {
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      
      if (code != null && code.isNotEmpty) {
        final product = await dbHelper.getProductByName(code);
        
        if (product != null) {
          setState(() {
            if (!_products.any((p) => p['id'] == product['id'])) {
              _products.add({
                'id': product['id'],
                'name': product['name'],
                'quantity': 1,
                'price': product['sale_price'],
              });
              log('Product added: ${product['name']}');
              FlutterRingtonePlayer().play(
                fromAsset: 'assets/img/beep.mp3',
              );
            }
          });
        }
      }
    }
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

    // Calcular total antes de descuentos
    double subtotal = 0.0;
    for (var product in _products) {
      subtotal += product['quantity'] * product['price'];
    }

    // Si no hay cliente seleccionado, preguntar si quiere seleccionar uno
    if (selectedCustomer == null) {
      final shouldSelectCustomer = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person_add, color: Colors.blue),
                SizedBox(width: 8),
                Text('Seleccionar Cliente'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Deseas asociar esta venta a un cliente?'),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El cliente ganará ${Customer.calculatePointsFromPurchase(subtotal)} punto${Customer.calculatePointsFromPurchase(subtotal) != 1 ? 's' : ''} con esta compra',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Continuar sin cliente'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Seleccionar cliente'),
              ),
            ],
          );
        },
      );

      if (shouldSelectCustomer == true) {
        // Mostrar diálogo de selección de cliente
        await _showCustomerSelectionDialog(subtotal);
        // Después de seleccionar cliente, no continuar automáticamente
        return;
      }
    } else {
      // Si ya hay cliente seleccionado, continuar directamente
      await _showDiscountSelectionDialog(subtotal);
    }

    // Si se seleccionó continuar sin cliente, proceder con descuentos
    if (selectedCustomer == null) {
      await _showDiscountSelectionDialog(subtotal);
    }
  }

  Future<void> _showCustomerSelectionDialog(double subtotal) async {
    // Cargar clientes si no están cargados
    if (customerController.customers.isEmpty) {
      await customerController.loadCustomers();
    }

    // Verificar si hay un cliente sugerido (el último usado o con más puntos)
    Customer? suggestedCustomer;
    if (customerController.customers.isNotEmpty) {
      // Buscar el cliente con compra más reciente
      suggestedCustomer = customerController.customers
          .where((c) => c.lastPurchase != null)
          .fold<Customer?>(null, (prev, curr) {
        if (prev == null) return curr;
        return curr.lastPurchase!.isAfter(prev.lastPurchase!) ? curr : prev;
      });
      
      // Si no hay cliente reciente, usar el que tiene más puntos
      suggestedCustomer ??= customerController.customers
            .reduce((prev, curr) => curr.loyaltyPoints > prev.loyaltyPoints ? curr : prev);
    }

    // Mostrar diálogo con sugerencia
    final selectedCustomerId = await showDialog<int?>(
      context: context,
      builder: (BuildContext context) {
        return CustomerSelectionDialog(suggestedCustomer: suggestedCustomer);
      },
    );

    if (selectedCustomerId != null) {
      // Buscar el cliente seleccionado
      final customer = customerController.customers.firstWhereOrNull(
        (c) => c.id == selectedCustomerId,
      );
      
      if (customer != null) {
        setState(() {
          selectedCustomer = customer;
        });
        
        // Continuar automáticamente con descuentos después de seleccionar cliente
        await _showDiscountSelectionDialog(subtotal);
      }
    }
    // Si se cancela la selección, no hacer nada (el usuario puede decidir continuar sin cliente)
  }

  Future<void> _showDiscountSelectionDialog(double subtotal) async {
    final selectedDiscount = await showDiscountSelectionDialog(
      context: context,
      totalAmount: subtotal,
    );

    // Aplicar descuento seleccionado
    if (selectedDiscount != null) {
      discountController.applyDiscount(selectedDiscount, subtotal);
    } else {
      discountController.removeDiscount();
    }

    // Calcular total final (con o sin descuento)
    final discountAmount = selectedDiscount?.calculateDiscountAmount(subtotal) ?? 0.0;
    final totalOrder = subtotal - discountAmount;

    // Mostrar diálogo de método de pago con el total final
    await _showPaymentMethodDialog(totalOrder, subtotal, discountAmount, selectedDiscount);
  }

  Future<void> _showPaymentMethodDialog(
    double totalOrder, 
    double subtotal, 
    double discountAmount, 
    dynamic selectedDiscount
  ) async {
    Get.put(PaymentController());
    
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return PaymentMethodDialog(
          totalAmount: totalOrder,
          onPaymentConfirmed: () => _processOrderWithNewPayment(
            totalOrder, 
            subtotal, 
            discountAmount, 
            selectedDiscount
          ),
        );
      },
    );
  }

  Future<void> _processOrderWithNewPayment(
    double totalOrder, 
    double subtotal, 
    double discountAmount, 
    dynamic selectedDiscount
  ) async {
    final paymentController = Get.find<PaymentController>();
    final paymentInfo = paymentController.getPaymentSummary();
    
    try {
      final order = {
        'order_date': DateTime.now().toIso8601String(),
        'totalOrden': totalOrder,
        'payment_method': paymentInfo['payment_method'],
        'customer_id': selectedCustomer?.id, // Incluir customer_id si hay cliente seleccionado
      };

      final orderId = await DatabaseHelper().insertOrderWithPayment(order);

      for (var item in _products) {
        await DatabaseHelper().insertOrderItem({
          'order_id': orderId,
          'product_id': item['id'],
          'quantity': item['quantity'],
          'price': item['price'],
        });

        // Actualizar stock del producto
        final currentProduct = await dbHelper.getProductByName(item['name']);
        if (currentProduct != null) {
          final newStock = currentProduct['stock'] - item['quantity'];
          await dbHelper.updateProductStock(item['id'], newStock);
        }
      }

      // Actualizar estadísticas del cliente y otorgar puntos de lealtad
      if (selectedCustomer != null) {
        await DatabaseHelper().updateCustomerPurchaseStats(
          selectedCustomer!.id!,
          totalOrder,
        );
        // Recargar datos del cliente para mostrar puntos actualizados
        await customerController.loadCustomers();
      }

      // Registrar en efectivo si es necesario
      if (paymentInfo['payment_method'] == 'efectivo' && cashController.isCashRegisterOpen) {
        await DatabaseHelper().registerCashSale(orderId, totalOrder);
      }

      setState(() {
        _products.clear();
        selectedCustomer = null; // Limpiar cliente seleccionado
      });

      // Mensaje de éxito con información de descuento
      String message = '✅ Venta procesada exitosamente!';
      if (selectedCustomer != null) {
        final pointsEarned = Customer.calculatePointsFromPurchase(totalOrder);
        message += '\n👤 Cliente: ${selectedCustomer!.name}';
        if (pointsEarned > 0) {
          message += '\n⭐ +$pointsEarned ${pointsEarned == 1 ? 'punto' : 'puntos'} ganado${pointsEarned == 1 ? '' : 's'}!';
        }
      }
      if (discountAmount > 0) {
        message += '\n💰 Subtotal: \$${subtotal.toStringAsFixed(2)}';
        message += '\n🎫 Descuento: -\$${discountAmount.toStringAsFixed(2)}';
        if (selectedDiscount != null) {
          message += ' (${selectedDiscount.name})';
        }
      }
      message += '\n💰 Total Final: \$${totalOrder.toStringAsFixed(2)}';
      
      final paymentDetails = paymentController.getPaymentDetails(totalOrder);
      message += '\n💳 $paymentDetails';

      Get.snackbar(
        'Venta Exitosa',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );

      FlutterRingtonePlayer().play(
        android: AndroidSounds.notification,
        ios: IosSounds.glass,
        looping: false,
        volume: 0.8,
      );

      // Limpiar información de pago y descuento
      paymentController.resetPaymentInfo();
      discountController.removeDiscount();

      // Navegar de regreso a la lista de órdenes con resultado exitoso
      Navigator.of(context).pop(true);

    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al procesar la venta: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildOrderSummary() {
    if (_products.isEmpty) {
      return SizedBox.shrink();
    }

    // Calcular subtotal
    double subtotal = 0.0;
    for (var product in _products) {
      subtotal += product['quantity'] * product['price'];
    }

    return Obx(() {
      final appliedDiscount = discountController.appliedDiscount.value;
      final hasDiscount = appliedDiscount != null;
      
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                Icon(Icons.receipt_long, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Text(
                  'Resumen',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Spacer(),
                if (!hasDiscount)
                  TextButton.icon(
                    onPressed: () => _showDiscountSelectionDialog(subtotal),
                    icon: Icon(Icons.local_offer, size: 14),
                    label: Text('Desc.', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal:',
                  style: TextStyle(fontSize: 13),
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            if (hasDiscount) ...[
              SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Descuento:',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          appliedDiscount.discount.displayValue,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '-\$${appliedDiscount.discountAmount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          discountController.removeDiscount();
                        },
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            SizedBox(height: 6),
            Divider(thickness: 1, height: 1),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  '\$${(hasDiscount ? appliedDiscount.finalAmount : subtotal).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, size: 24),
            SizedBox(width: 8),
            Text('Nueva Venta'),
          ],
        ),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_products.length} ${_products.length == 1 ? 'producto' : 'productos'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Sección del escáner QR con indicador visual
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: scannerController,
                  onDetect: _handleBarcodeDetection,
                ),
                // Overlay con guía visual
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Instrucciones en la parte superior
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Escanea el código QR del producto',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón de linterna
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.black.withOpacity(0.6),
                    onPressed: () {
                      scannerController.toggleTorch();
                    },
                    child: Icon(Icons.flash_on, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de productos mejorada
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Encabezado de la lista
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_basket, color: Utils.colorBotones, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Productos en el carrito',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de productos
                  Expanded(
                    child: _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Escanea productos para agregarlos',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            itemCount: _products.length,
                            separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              final itemTotal = product['quantity'] * product['price'];
                              return Dismissible(
                                key: Key(product['id'].toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: Icon(Icons.delete, color: Colors.white, size: 32),
                                ),
                                onDismissed: (direction) {
                                  setState(() {
                                    _products.removeAt(index);
                                  });
                                  Get.snackbar(
                                    'Producto eliminado',
                                    'Se ha quitado del carrito',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.orange,
                                    colorText: Colors.white,
                                    duration: Duration(seconds: 2),
                                  );
                                },
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: IconButton(
                                    icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                                    onPressed: () {
                                      setState(() {
                                        _products.removeAt(index);
                                      });
                                      Get.snackbar(
                                        'Producto eliminado',
                                        'Se ha quitado del carrito',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.orange,
                                        colorText: Colors.white,
                                        duration: Duration(seconds: 2),
                                      );
                                    },
                                  ),
                                  title: Text(
                                    product['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '\$${product['price'].toStringAsFixed(2)} c/u',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Botón decrementar
                                      Container(
                                        width: 32,
                                        height: 32,
                                        child: ElevatedButton(
                                          onPressed: () => _decrementQuantity(index),
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(),
                                            backgroundColor: Utils.colorBotones,
                                            padding: EdgeInsets.zero,
                                            elevation: 2,
                                          ),
                                          child: Icon(Icons.remove, color: Colors.white, size: 16),
                                        ),
                                      ),
                                      // Cantidad y total
                                      Container(
                                        width: 70,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${product['quantity']}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '\$${itemTotal.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Utils.colorBotones,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Botón incrementar
                                      Container(
                                        width: 32,
                                        height: 32,
                                        child: ElevatedButton(
                                          onPressed: () => _incrementQuantity(index),
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(),
                                            backgroundColor: Utils.colorBotones,
                                            padding: EdgeInsets.zero,
                                            elevation: 2,
                                          ),
                                          child: Icon(Icons.add, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          // Widget de resumen de totales
          _buildOrderSummary(),
          
          // Botón de registrar orden mejorado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _products.isEmpty ? null : () {
                  _registerOrder();
                },
                icon: Icon(Icons.check_circle, size: 24),
                label: Text(
                  'Procesar Venta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Utils.colorBotones,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  elevation: _products.isEmpty ? 0 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
