import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bellezapp/controllers/loading_controller.dart';
import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:bellezapp/pages/add_product_page.dart';
import 'package:bellezapp/pages/edit_product_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:get/get.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  ProductListPageState createState() => ProductListPageState();
}

class ProductListPageState extends State<ProductListPage> {
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _allProducts = [];
  final dbHelper = DatabaseHelper();
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final loadingC = Get.find<LoadingController>();
  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  void _loadProducts() async {
    loadingC.setOnLoading();
    try {
      final products = await dbHelper.getProducts();
      log(products.toString());
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });
    } catch (e) {
      log('Error loading products: $e');
    } finally {
      loadingC.setOffLoading();
    }
  }

  void _filterProducts(String searchText) {
    setState(() {
      if (searchText.isNotEmpty) {
        _filteredProducts = _allProducts.where((product) {
          final name = product['name'].toLowerCase();
          final description = product['description'].toLowerCase();
          final category = product['category_name']?.toLowerCase() ?? '';
          final supplier = product['supplier_name']?.toLowerCase() ?? '';
          final location = product['location_name']?.toLowerCase() ?? '';
          final searchLower = searchText.toLowerCase();
          return name.contains(searchLower) ||
              description.contains(searchLower) ||
              category.contains(searchLower) ||
              supplier.contains(searchLower) ||
              location.contains(searchLower);
        }).toList();
      } else {
        _filteredProducts = _allProducts;
      }
    });
  }

  void _showAllProducts() {
    setState(() {
      _filteredProducts = _allProducts;
    });
  }

  void _showNearExpiryProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final expiryDate = DateTime.tryParse(product['expirity_date'] ?? '');
        return expiryDate != null &&
            expiryDate.difference(DateTime.now()).inDays <= 30;
      }).toList();
    });
  }

  void _showLowStockProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final stock = product['stock'] ?? 0;
        return stock < 10;
      }).toList();
    });
  }

  void _deleteProduct(int id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar este producto?',
    );
    if (confirmed) {
      loadingC.setOnLoading();
      try {
        await dbHelper.deleteProduct(id);
        _loadProducts();
      } catch (e) {
        log('Error deleting product: $e');
      } finally {
        loadingC.setOffLoading();
      }
    }
  }

  String formatNumber(double number) {
    return number % 1 == 0 ? number.toInt().toString() : number.toString();
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
            cursorColor: Utils.colorBotones,
            decoration: InputDecoration(
                prefixIconColor: Utils.colorBotones,
                floatingLabelStyle: TextStyle(
                    color: Utils.colorBotones, fontWeight: FontWeight.bold),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Utils.colorBotones, width: 3),
                ),
                border: OutlineInputBorder(),
                hintText: 'Cantidad de stock a añadir'),
          ),
          actions: [
            Utils.elevatedButton('Cancelar', Utils.no, () {
              Navigator.of(context).pop();
            }),
            Utils.elevatedButton('Añadir', Utils.yes, () async {
              loadingC.setOnLoading();
              try {
                final int stockToAdd = int.parse(stockController.text);
                await dbHelper.addProductStock(productId, stockToAdd);
                _loadProducts();
              } catch (e) {
                log('Error adding stock: $e');
              } finally {
                loadingC.setOffLoading();
                Navigator.of(context).pop();
              }
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => LoadingOverlay(
        progressIndicator: Utils.loadingCustom(),
        color: Colors.white.withOpacity(0.6),
        isLoading: loadingC.getLoading,
        child: Scaffold(
          backgroundColor: Utils.colorFondo,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Utils.elevatedButton('Todos', Utils.colorBotones, () {
                      _showAllProducts();
                    }),
                    Utils.elevatedButton('Caducidad prox.', Utils.colorBotones,
                        () {
                      _showNearExpiryProducts();
                    }),
                    Utils.elevatedButton('Stock bajo', Utils.colorBotones, () {
                      _showLowStockProducts();
                    }),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        spacing: 8, // Espaciado horizontal entre elementos
                        runSpacing: 8, // Espaciado vertical entre filas
                        children: _filteredProducts.map((product) {
                          final stock = product['stock'] ?? 0;
                          final expiryDate =
                              DateTime.tryParse(product['expirity_date'] ?? '');
                          final isLowStock = stock < 10;
                          final isNearExpiry = expiryDate != null &&
                              expiryDate.difference(DateTime.now()).inDays <=
                                  30;
                          final weight = product['weight'] ?? '';
                          final locationName =
                              product['location_name'] ?? 'Sin ubicación';
                          final purchasePrice =
                              formatNumber(product['purchase_price']);
                          final salePrice = formatNumber(product['sale_price']);
                          final fotoBase64 = product['foto'] ?? '';

                          Uint8List? imageBytes;
                          if (fotoBase64.isNotEmpty) {
                            try {
                              imageBytes = base64Decode(fotoBase64);
                            } catch (e) {
                              imageBytes =
                                  null; // Si ocurre un error, asigna null
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
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(8),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
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
                                            color:
                                                Colors.white, // Color del ícono
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Utils.add,
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              _showAddStockDialog(
                                                  product['id']);
                                            },
                                            icon: const Icon(Icons.add),
                                            color:
                                                Colors.white, // Color del ícono
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
                                            color:
                                                Colors.white, // Color del ícono
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
                                              '${purchasePrice.toString()} Bs.',
                                            ),
                                            Utils.bigTextLlaveValor(
                                              'Precio de venta: ',
                                              '\n${salePrice.toString()} Bs.',
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
                    Padding(
                      padding: EdgeInsets.only(left: 10, top: 10),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: _isExpanded ? 400 : 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Utils.colorBotones.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Utils.colorBotones,
                              width: 4,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedAlign(
                                duration: Duration(milliseconds: 300),
                                alignment: _isExpanded
                                    ? Alignment.centerLeft
                                    : Alignment.center,
                                child: IconButton(
                                  icon: Icon(
                                    _isExpanded ? Icons.close : Icons.search,
                                    color: Utils.colorBotones,
                                    size: 35,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: AnimatedAlign(
                                  duration: Duration(milliseconds: 300),
                                  alignment: _isExpanded
                                      ? Alignment.center
                                      : Alignment.centerRight,
                                  child: _isExpanded
                                      ? TextField(
                                          controller: _searchController,
                                          onChanged: _filterProducts,
                                          decoration: InputDecoration(
                                            hintText: 'Buscar un producto...',
                                            border: InputBorder.none,
                                          ),
                                        )
                                      : SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Utils.colorBotones,
            onPressed: () async {
              Get.to(AddProductPage());
            },
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndShowPdf(
      BuildContext context, String productName) async {
    loadingC.setOnLoading();
    try {
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
    } catch (e) {
      log('Error generating PDF: $e');
    } finally {
      loadingC.setOffLoading();
    }
  }
}