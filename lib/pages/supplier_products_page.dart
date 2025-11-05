import 'package:bellezapp/controllers/product_controller.dart';
import 'package:bellezapp/pages/edit_product_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class SupplierProductsPage extends StatefulWidget {
  final String supplierId;
  final String supplierName;

  const SupplierProductsPage({
    super.key, 
    required this.supplierId, 
    required this.supplierName
  });

  @override
  SupplierProductsPageState createState() => SupplierProductsPageState();
}

class SupplierProductsPageState extends State<SupplierProductsPage> {
  // Usar la misma instancia del controlador que ya existe
  late final ProductController productController;

  @override
  void initState() {
    super.initState();
    // Intentar obtener una instancia existente, o crear una nueva si no existe
    try {
      productController = Get.find<ProductController>();
    } catch (e) {
      productController = Get.put(ProductController());
    }
    
    // ⭐ CARGAR productos con filtro de proveedor Y tienda actual
    productController.loadProducts(supplierId: widget.supplierId);
  }

  String _getImageUrl(Map<String, dynamic> product) {
    final foto = product['foto'];
    if (foto == null || foto.toString().isEmpty) {
      return '';
    }
    return foto.toString();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: Text(widget.supplierName),
        backgroundColor: Utils.colorBotones,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (productController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = productController.products;

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, 
                  size: 80, 
                  color: Colors.grey[400]
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay productos de este proveedor',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      }),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] ?? 'Sin nombre';
    final stock = product['stock'] ?? 0;
    final salePrice = double.tryParse(product['salePrice'].toString()) ?? 0.0;
    final imageUrl = _getImageUrl(product);
    final isLowStock = stock < 10;

    return GestureDetector(
      onTap: () async {
        await Get.to(() => EditProductPage(product: product));
        productController.loadProducts(supplierId: widget.supplierId);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Utils.colorFondoCards,
          borderRadius: BorderRadius.circular(12),
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
            // Imagen
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/img/perfume.webp',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 120,
                            ),
                          )
                        : Image.asset(
                            'assets/img/perfume.webp',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 120,
                          ),
                  ),
                ),
                if (isLowStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Bajo stock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Información
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock: $stock',
                          style: TextStyle(
                            fontSize: 12,
                            color: isLowStock ? Colors.red : Colors.grey[600],
                            fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(salePrice),
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
            ),
          ],
        ),
      ),
    );
  }
}
