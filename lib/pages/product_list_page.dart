import 'dart:developer';
import 'dart:io';
import 'package:bellezapp/controllers/product_controller.dart';
import 'package:bellezapp/controllers/auth_controller.dart';
import 'package:bellezapp/pages/add_product_page.dart';
import 'package:bellezapp/pages/edit_product_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barcode_widget/barcode_widget.dart';
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
  // Usar la misma instancia del controlador que ya existe
  late final ProductController productController;
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();
  
  String _activeFilter = 'todos';
  Map<String, bool> _expandedBadges = {}; // Para controlar qué badges están expandidos

  @override
  void initState() {
    super.initState();
    // Intentar obtener una instancia existente, o crear una nueva si no existe
    try {
      productController = Get.find<ProductController>();
    } catch (e) {
      productController = Get.put(ProductController());
    }
    
    // Ejecutar después del primer frame para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  void _loadProducts() {
    // ⭐ SIEMPRE cargar productos de la tienda actual
    productController.loadProductsForCurrentStore();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final searchText = _searchController.text.toLowerCase();
    var products = productController.products;

    // Aplicar búsqueda
    if (searchText.isNotEmpty) {
      products = products.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        final description = (product['description'] ?? '').toString().toLowerCase();
        final category = (product['categoryId']?['name'] ?? '').toString().toLowerCase();
        final supplier = (product['supplierId']?['name'] ?? '').toString().toLowerCase();
        final location = (product['locationId']?['name'] ?? '').toString().toLowerCase();
        return name.contains(searchText) || 
               description.contains(searchText) ||
               category.contains(searchText) ||
               supplier.contains(searchText) ||
               location.contains(searchText);
      }).toList();
    }

    // Aplicar filtro de stock bajo
    if (_activeFilter == 'stock') {
      products = products.where((product) {
        final stock = product['stock'] ?? 0;
        return stock < 10;
      }).toList();
    }

    // Aplicar filtro de próximo a vencer
    if (_activeFilter == 'expiry') {
      products = products.where((product) {
        final expiryDate = DateTime.tryParse(product['expiryDate']?.toString() ?? '');
        return expiryDate != null && 
               expiryDate.difference(DateTime.now()).inDays <= 30;
      }).toList();
    }

    return products;
  }

  String _getImageUrl(Map<String, dynamic> product) {
    final foto = product['foto'];
    if (foto == null || foto.toString().isEmpty) {
      return '';
    }
    // La foto ya es una URL completa de Cloudinary
    return foto.toString();
  }

  void _showAddStockDialog(String productId, String productName) {
    final stockController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Utils.colorBotones.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icono animado
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Utils.colorBotones.withOpacity(0.8),
                              Utils.colorBotones,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Utils.colorBotones.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Título
                      Text(
                        'Añadir Stock',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      // Nombre del producto
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Utils.colorBotones.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                              color: Utils.colorBotones,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                productName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Utils.colorBotones,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Campo de cantidad con diseño moderno
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextFormField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          cursorColor: Utils.colorBotones,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Utils.colorBotones,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Icon(
                                Icons.add_circle_outline,
                                color: Utils.colorBotones,
                                size: 32,
                              ),
                            ),
                            suffixText: 'unidades',
                            suffixStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 32,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa una cantidad';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Cantidad debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      // Texto de ayuda
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                          SizedBox(width: 6),
                          Text(
                            'Ingresa la cantidad a agregar al inventario',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),
                      
                      // Botones con diseño moderno
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            // Botón Cancelar
                            Expanded(
                              child: Container(
                                height: 44,
                                child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey[300]!, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          
                          // Botón Añadir
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    Utils.colorBotones,
                                    Utils.colorBotones.withOpacity(0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Utils.colorBotones.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    final stockToAdd = int.parse(stockController.text);
                                    Navigator.of(context).pop();
                                    
                                    final success = await productController.updateStock(
                                      id: productId,
                                      quantity: stockToAdd,
                                      operation: 'add',
                                    );
                                    
                                    if (success) {
                                      _loadProducts();
                                      // Mostrar snackbar de éxito
                                      Get.snackbar(
                                        'Stock Actualizado',
                                        'Se agregaron $stockToAdd unidades correctamente',
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                        icon: Icon(Icons.check_circle, color: Colors.white),
                                        duration: Duration(seconds: 2),
                                      );
                                    }
                                  }
                                },
                                icon: Icon(Icons.add_shopping_cart, size: 20),
                                label: Text(
                                  'Añadir Stock',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndShowPdf(BuildContext context, String productName) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, 100 * PdfPageFormat.mm),
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
      Get.snackbar(
        'Error',
        'No se pudo generar el PDF',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _deleteProduct(String productId, String productName) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar "$productName"?',
    );
    if (confirmed) {
      final result = await productController.deleteProduct(productId);
      if (result) {
        Get.snackbar(
          'Éxito',
          'Producto eliminado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadProducts();
      }
    }
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

  Widget _buildImprovedFilterChip(String label, String value, IconData icon, Color color) {
    final isActive = _activeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = value;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onChanged: (value) => setState(() {}),
                    style: TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar productos por nombre, categoría, proveedor...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: Utils.colorBotones, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
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
                    Obx(() => Container(
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
                    )),
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
          
          // Lista de productos
          Expanded(
            child: Obx(() {
              if (productController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = _filteredProducts;

              if (products.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: (products.length / 2).ceil(),
                itemBuilder: (context, rowIndex) {
                  final leftIndex = rowIndex * 2;
                  final rightIndex = leftIndex + 1;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildProductCard(products[leftIndex]),
                          ),
                          if (rightIndex < products.length) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildProductCard(products[rightIndex]),
                            ),
                          ] else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () async {
          final result = await Get.to(() => const AddProductPage());
          // Si result es true, significa que se creó un producto
          if (result == true) {
            print('DEBUG ProductListPage - Producto creado, recargando lista...');
            _loadProducts();
          }
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['_id'] ?? '';
    final name = product['name'] ?? 'Sin nombre';
    final description = product['description'] ?? '';
    final stock = product['stock'] ?? 0;
    final salePrice = product['salePrice'] ?? 0.0;
    final purchasePrice = product['purchasePrice'] ?? 0.0;
    final weight = product['weight'] ?? '';
    final imageUrl = _getImageUrl(product);
    final isLowStock = stock < 10;
    
    // Extraer nombres de relaciones
    final locationName = product['locationId'] is Map 
        ? product['locationId']['name'] ?? 'Sin ubicación'
        : 'Sin ubicación';
    
    // Verificar fecha de vencimiento
    final expiryDate = DateTime.tryParse(product['expiryDate']?.toString() ?? '');
    final isNearExpiry = expiryDate != null && 
        expiryDate.difference(DateTime.now()).inDays <= 30;

    return Container(
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
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/img/perfume.webp',
                            fit: BoxFit.cover,
                            height: 120,
                            width: double.infinity,
                          ),
                        )
                      : Image.asset(
                          'assets/img/perfume.webp',
                          fit: BoxFit.cover,
                          height: 120,
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
                            final key = '${productId}_stock';
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
                              if (_expandedBadges['${productId}_stock'] ?? false) ...[
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
                            final key = '${productId}_expiry';
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
                              if (_expandedBadges['${productId}_expiry'] ?? false) ...[
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
                    _generateAndShowPdf(context, name);
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
                      data: name,
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
                      onTap: () async {
                        final result = await Get.to(() => EditProductPage(product: product));
                        // Si result es true, significa que se actualizó el producto
                        if (result == true) {
                          print('DEBUG ProductListPage - Producto actualizado, recargando lista...');
                          _loadProducts();
                        }
                      },
                      tooltip: 'Editar',
                    ),
                    SizedBox(width: 4),
                    _buildCompactActionButton(
                      icon: Icons.add,
                      color: Utils.add,
                      onTap: () => _showAddStockDialog(productId, name),
                      tooltip: 'Añadir stock',
                    ),
                    SizedBox(width: 4),
                    _buildCompactActionButton(
                      icon: Icons.delete,
                      color: Utils.delete,
                      onTap: () => _deleteProduct(productId, name),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Contenido de la card
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del producto
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Utils.colorGnav,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                // Descripción
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 6),
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
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoItem('Vencimiento', 
                              expiryDate != null
                                  ? expiryDate.toLocal().toString().split(' ')[0]
                                  : 'Sin fecha',
                              isNearExpiry ? Colors.orange : Colors.grey, Icons.schedule),
                          _buildInfoItem('Tamaño', 
                              weight.isNotEmpty ? weight : 'Sin especificar', Colors.purple, Icons.straighten),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6),
                // Precios destacados
                Container(
                  padding: EdgeInsets.all(5),
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
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${purchasePrice.toStringAsFixed(2)} Bs.',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Precio venta:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Utils.colorBotones,
                              ),
                            ),
                          ),
                          Text(
                            '${salePrice.toStringAsFixed(2)} Bs.',
                            style: TextStyle(
                              fontSize: 14,
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
  }

  Widget _buildEmptyState() {
    String mensaje;
    IconData icono = Icons.inventory_2_outlined;

    if (_searchController.text.isNotEmpty) {
      mensaje = 'No se encontraron productos que coincidan con tu búsqueda.';
    } else if (_activeFilter == 'stock') {
      mensaje = 'No hay productos con stock bajo.';
    } else if (_activeFilter == 'expiry') {
      mensaje = 'No hay productos próximos a vencer.';
    } else {
      mensaje = 'No hay productos registrados. Agrega tu primer producto usando el botón "+".';
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
            onPressed: _loadProducts,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
