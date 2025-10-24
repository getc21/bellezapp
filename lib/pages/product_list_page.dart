import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bellezapp/controllers/loading_controller.dart';
import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/controllers/product_controller.dart';
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
  final dbHelper = DatabaseHelper();
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final loadingC = Get.find<LoadingController>();
  final themeController = Get.find<ThemeController>();
  final productController = Get.find<ProductController>();

  @override
  void initState() {
    super.initState();
    // Ya no necesitamos cargar productos aquí, el controller lo maneja
  }

  void _deleteProduct(int id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar este producto?',
    );
    if (confirmed) {
      try {
        await productController.deleteProduct(id);
      } catch (e) {
        log('Error deleting product: $e');
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
              try {
                final int stockToAdd = int.parse(stockController.text);
                await productController.addProductStock(productId, stockToAdd);
                Navigator.of(context).pop();
              } catch (e) {
                log('Error adding stock: $e');
              }
            }),
          ],
        );
      },
    );
  }

  Widget _buildImprovedFilterChip(String label, String value, IconData icon, Color color) {
    return Obx(() {
      final isActive = productController.activeFilter == value;
      return GestureDetector(
        onTap: () {
          switch (value) {
            case 'todos':
              productController.showAllProducts();
              break;
            case 'stock':
              productController.showLowStockProducts();
              break;
            case 'expiry':
              productController.showNearExpiryProducts();
              break;
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: color,
              width: 1.5,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ] : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : color,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => LoadingOverlay(
        progressIndicator: Utils.loadingCustom(),
        color: Colors.white.withOpacity(0.6),
        isLoading: productController.isLoading,
        child: Scaffold(
          backgroundColor: Utils.colorFondo,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de sección
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtros rápidos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Utils.colorGnav,
                          ),
                        ),
                        Obx(() => Text(
                          '${productController.filteredProducts.length} productos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )),
                      ],
                    ),
                    SizedBox(height: 5),
                    // Chips de filtro mejorados
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildImprovedFilterChip('Todos', 'todos', Icons.inventory_2_outlined, Colors.blue),
                          SizedBox(width: 8),
                          _buildImprovedFilterChip('Stock bajo', 'stock', Icons.warning_amber_outlined, Colors.red),
                          SizedBox(width: 8),
                          _buildImprovedFilterChip('Prox. vencer', 'expiry', Icons.schedule_outlined, Colors.orange),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Obx(() => SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        spacing: 8, // Espaciado horizontal entre elementos
                        runSpacing: 8, // Espaciado vertical entre filas
                        children: productController.filteredProducts.map((product) {
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
                    )),
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
                                      if (!_isExpanded) {
                                        _searchController.clear();
                                        productController.filterProducts('');
                                      }
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
                                          onChanged: (text) => productController.filterProducts(text),
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
              final result = await Get.to(AddProductPage());
              if (result == true) {
                // Refrescar la lista cuando se agregue un producto
                productController.refreshProducts();
              }
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