import 'dart:convert';
import 'dart:io';

import 'package:bellezapp/database/database_helper.dart';
import 'package:bellezapp/pages/edit_product_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class LocationProductsPage extends StatefulWidget {
  final int locationId;
  final String locationName;

  const LocationProductsPage({super.key, required this.locationId, required this.locationName});

  @override
  LocationProductsPageState createState() => LocationProductsPageState();
}

class LocationProductsPageState extends State<LocationProductsPage> {
  List<Map<String, dynamic>> _products = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    final products = await dbHelper.getProductsByLocation(widget.locationId);
    setState(() {
      _products = products;
    });
  }

  void _deleteProduct(int id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar este producto?',
    );
    if (confirmed) {
      await dbHelper.deleteProduct(id);
      _loadProducts();
    }
  }

  void _showAddStockDialog(int productId) {
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Utils.colorFondoCards,
          title: Text('Añadir Stock'),
          content: TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Cantidad de stock a añadir'),
          ),
          actions: [
            Utils.elevatedButton('Cancelar', Utils.no, () {
              Navigator.of(context).pop();
            }),
            Utils.elevatedButton('Añadir', Utils.yes, () async {
              final int stockToAdd = int.parse(stockController.text);
                await dbHelper.addProductStock(productId, stockToAdd);
                _loadProducts();
                Navigator.of(context).pop();
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.locationName),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Utils.colorFondo,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 8, // Espaciado horizontal entre elementos
                    runSpacing: 8, // Espaciado vertical entre filas
                    children: _products.map((product) {
                      final stock = product['stock'] ?? 0;
                      final expiryDate =
                          DateTime.tryParse(product['expirity_date'] ?? '');
                      final isLowStock = stock < 10;
                      final isNearExpiry = expiryDate != null &&
                          expiryDate.difference(DateTime.now()).inDays <= 30;
                      final weight = product['weight'] ?? '';
                      final locationName =
                          product['location_name'] ?? 'Sin ubicación';
                      final purchasePrice = product['purchase_price'] ?? 0.0;
                      final salePrice = product['sale_price'] ?? 0.0;
                      final fotoBase64 = product['foto'] ?? '';

                      Uint8List? imageBytes;
                      if (fotoBase64.isNotEmpty) {
                        try {
                          imageBytes = base64Decode(fotoBase64);
                        } catch (e) {
                          imageBytes = null; // Si ocurre un error, asigna null
                        }
                      }
                      return Container(
                        width: MediaQuery.of(context).size.width *
                            0.45, // Ajusta el ancho
                        decoration: BoxDecoration(
                          color: Utils.colorFondoCards,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen con iconos
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                    child: imageBytes != null
                                        ? Image.memory(
                                            imageBytes,
                                            height: 132,
                                            width: double.infinity,
                                            fit: BoxFit.fill,
                                          )
                                        : Image.asset(
                                            'assets/img/perfume.webp',
                                            fit: BoxFit.fill,
                                            height: 130,
                                            width: double.infinity,
                                          ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Utils.edit, // Color de fondo
                                        borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(
                                                5)), // Bordes redondeados
                                      ), // Espaciado interno
                                      child: IconButton(
                                        onPressed: () {
                                          Get.to(EditProductPage(
                                              product: product));
                                        },
                                        icon: const Icon(Icons.edit),
                                        color: Colors.white, // Color del ícono
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Utils.add,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          _showAddStockDialog(product['id']);
                                        },
                                        icon: const Icon(Icons.add),
                                        color: Colors.white, // Color del ícono
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Utils.delete,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          _deleteProduct(product['id']);
                                        },
                                        icon: const Icon(Icons.delete),
                                        color: Colors.white, // Color del ícono
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Utils.textTitle(
                                        product['name'] ?? 'Producto'),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: GestureDetector(
                                    onTap: () {
                                      _generateAndShowPdf(
                                          context, product['name']);
                                    },
                                    child: BarcodeWidget(
                                      backgroundColor: Colors.white,
                                      barcode: Barcode.qrCode(),
                                      data: product['name'] ?? '',
                                      width: 40,
                                      height: 40,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Utils.textDescription(
                                  product['description'] ?? 'Descripción'),
                            ),
                            const SizedBox(height: 4),
                            // Fecha de vencimiento y QR
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Utils.textLlaveValor(
                                          'Fecha de caducidad: ',
                                          expiryDate != null
                                              ? expiryDate
                                                  .toLocal()
                                                  .toString()
                                                  .split(' ')[0]
                                              : 'Sin fecha',
                                          color: isNearExpiry
                                              ? Colors.orange
                                              : Utils.defaultColor,
                                        ),
                                        Utils.textLlaveValor(
                                            'Stock: ',
                                            stock != null
                                                ? '$stock'
                                                : 'Sin stock',
                                            color: isLowStock
                                                ? Colors.red
                                                : Utils.defaultColor),
                                        Utils.textLlaveValor(
                                          'Tamaño: ',
                                          weight.isNotEmpty
                                              ? weight
                                              : 'Sin tamaño',
                                        ),
                                        Utils.textLlaveValor(
                                            'Ubicacion: ', locationName),
                                        Utils.textLlaveValor(
                                          'Precio de compra: ',
                                          purchasePrice.toString(),
                                        ),
                                        Utils.textLlaveValor(
                                          'Precio de venta: ',
                                          salePrice.toString(),
                                        ),
                                        Utils.espacio10
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndShowPdf(
      BuildContext context, String productName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat:
            PdfPageFormat(80 * PdfPageFormat.mm, 100 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.GridView(
            crossAxisCount: 4,
            childAspectRatio: 1,
            children: List.generate(12, (index) {
              return pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(4),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: productName,
                      width: 40,
                      height: 40,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      productName,
                      style: pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();

    final filePath = '${directory.path}/$productName.pdf';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // Abre el archivo PDF con un visor externo
    await OpenFilex.open(filePath);
  }
}