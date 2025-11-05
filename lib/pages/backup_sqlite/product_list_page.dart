import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bellezapp/controllers/loading_controller.dart';
import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:bellezapp/pages/add_product_page.dart';
import 'package:bellezapp/pages/edit_product_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/mixins/store_aware_mixin.dart';
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

class ProductListPageState extends State<ProductListPage> with StoreAwareMixin {
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _allProducts = [];
  final dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  final loadingC = Get.find<LoadingController>();
  final themeController = Get.find<ThemeController>();
  String _activeFilter = 'todos'; // Estado del filtro activo
  Map<int, bool> _expandedBadges = {}; // Para controlar qué badges están expandidos

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  @override
  void reloadData() {
    print('🔄 Recargando productos por cambio de tienda');
    _loadProducts();
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
      _activeFilter = 'todos';
      _filteredProducts = _allProducts;
    });
  }

  void _showNearExpiryProducts() {
    setState(() {
      _activeFilter = 'expiry';
      _filteredProducts = _allProducts.where((product) {
        final expiryDate = DateTime.tryParse(product['expirity_date'] ?? '');
        return expiryDate != null &&
            expiryDate.difference(DateTime.now()).inDays <= 30;
      }).toList();
    });
  }

  void _showLowStockProducts() {
    setState(() {
      _activeFilter = 'stock';
      _filteredProducts = _allProducts.where((product) {
        final stock = product['stock'] ?? 0;
        return stock < 10;
      }).toList();
    });
  }

  Widget _buildImprovedFilterChip(String label, String value, IconData icon, Color color) {
    final isActive = _activeFilter == value;
    return GestureDetector(
      onTap: () {
        switch (value) {
          case 'todos':
            _showAllProducts();
            break;
          case 'stock':
            _showLowStockProducts();
            break;
          case 'expiry':
            _showNearExpiryProducts();
            break;
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
              size: 14,
              color: isActive ? Colors.white : color,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildInfoItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
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
              // Header mejorado con búsqueda prominente
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                        onChanged: _filterProducts,
                        style: TextStyle(fontSize: 13),
                        enableInteractiveSelection: true,
                        decoration: InputDecoration(
                          hintText: 'Buscar productos por nombre, categoría, proveedor...',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                          prefixIcon: Icon(Icons.search, color: Utils.colorBotones, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterProducts('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // Filtros rápidos con contador
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtros rápidos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Utils.colorBotones.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_filteredProducts.length} productos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Utils.colorBotones,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildImprovedFilterChip('Todos', 'todos', Icons.inventory_2_outlined, Colors.blue),
                        _buildImprovedFilterChip('Stock bajo', 'stock', Icons.warning_amber_outlined, Colors.red),
                        _buildImprovedFilterChip('Prox. vencer', 'expiry', Icons.schedule_outlined, Colors.orange),
                      ],
                    ),
                    SizedBox(height: 6),
                  ],
                ),
              ),
              Expanded(
                child: _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12, // Espaciado horizontal entre elementos
                          runSpacing: 12, // Espaciado vertical entre filas
                          children: _filteredProducts.map((product) {
                      final stock = product['stock'] ?? 0;
                      final expiryDate =
                          DateTime.tryParse(product['expirity_date'] ?? '');
                      final isLowStock = stock < 10;
                      final isNearExpiry = expiryDate != null &&
                          expiryDate.difference(DateTime.now()).inDays <= 30;
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
                          imageBytes = null;
                        }
                      }

                      return Container(
                        width: MediaQuery.of(context).size.width * 0.44,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen con badges de estado
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: imageBytes != null
                                        ? Image.memory(
                                            imageBytes,
                                            height: 140,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/img/perfume.webp',
                                            fit: BoxFit.cover,
                                            height: 140,
                                            width: double.infinity,
                                          ),
                                  ),
                                ),
                                // Badges de estado en la esquina superior derecha
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isLowStock)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              final key = product['id'] * 2; // ID único para stock bajo
                                              _expandedBadges[key] = !(_expandedBadges[key] ?? false);
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: Duration(milliseconds: 200),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.warning, color: Colors.white, size: 10),
                                                if (_expandedBadges[product['id'] * 2] ?? false) ...[
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'Stock bajo',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (isLowStock && isNearExpiry) SizedBox(height: 3),
                                      if (isNearExpiry)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              final key = product['id'] * 2 + 1; // ID único para vencimiento
                                              _expandedBadges[key] = !(_expandedBadges[key] ?? false);
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: Duration(milliseconds: 200),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.schedule, color: Colors.white, size: 10),
                                                if (_expandedBadges[product['id'] * 2 + 1] ?? false) ...[
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'Vence pronto',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // QR Code en la esquina superior izquierda
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      _generateAndShowPdf(context, product['name']);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: BarcodeWidget(
                                        backgroundColor: Colors.transparent,
                                        barcode: Barcode.qrCode(),
                                        data: product['name'] ?? '',
                                        width: 21,
                                        height: 21,
                                      ),
                                    ),
                                  ),
                                ),
                                // Botones de acción en la parte inferior derecha (horizontal)
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildCompactActionButton(
                                        icon: Icons.edit,
                                        color: Utils.edit,
                                        onTap: () => Get.to(EditProductPage(product: product)),
                                        tooltip: 'Editar',
                                      ),
                                      SizedBox(width: 4),
                                      _buildCompactActionButton(
                                        icon: Icons.add,
                                        color: Utils.add,
                                        onTap: () => _showAddStockDialog(product['id']),
                                        tooltip: 'Añadir stock',
                                      ),
                                      SizedBox(width: 4),
                                      _buildCompactActionButton(
                                        icon: Icons.delete,
                                        color: Utils.delete,
                                        onTap: () => _deleteProduct(product['id']),
                                        tooltip: 'Eliminar',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Contenido de la card
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Título del producto
                                  Text(
                                    product['name'] ?? 'Producto',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Utils.colorGnav,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 3),
                                  // Descripción
                                  Text(
                                    product['description'] ?? 'Sin descripción',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  // Información principal en formato grid
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildInfoItem('Stock', '$stock', 
                                                isLowStock ? Colors.red : Colors.green, Icons.inventory),
                                            _buildInfoItem('Ubicación', locationName, Colors.blue, Icons.location_on),
                                          ],
                                        ),
                                        SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildInfoItem('Vencimiento', 
                                                expiryDate != null
                                                    ? expiryDate.toLocal().toString().split(' ')[0]
                                                    : 'Sin fecha',
                                                isNearExpiry ? Colors.orange : Colors.grey, Icons.schedule),
                                            _buildInfoItem('Tamaño', 
                                                weight.isNotEmpty ? weight : 'N/A', Colors.purple, Icons.straighten),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  // Precios destacados
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Utils.colorBotones.withOpacity(0.1), Colors.transparent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Utils.colorBotones.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Precio compra:',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              '${purchasePrice} Bs.',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 3),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Precio venta:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Utils.colorBotones,
                                              ),
                                            ),
                                            Text(
                                              '${salePrice} Bs.',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Utils.colorBotones,
                                              ),
                                            ),
                                          ],
                                        ),
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

  Widget _buildEmptyState() {
    String mensaje;
    IconData icono = Icons.inventory_2_outlined;

    if (_searchController.text.isNotEmpty) {
      mensaje = 'No se encontraron productos que coincidan con tu búsqueda.';
    } else if (_activeFilter == 'stock') {
      mensaje = 'No hay productos con stock bajo en esta tienda.';
    } else if (_activeFilter == 'expiry') {
      mensaje = 'No hay productos próximos a vencer en esta tienda.';
    } else {
      mensaje = 'No hay productos en esta tienda. Agrega tu primer producto usando el botón "+".';
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
              icono,
              size: 80,
              color: Utils.colorBotones,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin Productos',
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
              loadingC.setOnLoading();
              _loadProducts();
              loadingC.setOffLoading();
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
}