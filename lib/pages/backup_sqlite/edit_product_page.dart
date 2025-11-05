import 'dart:io';
import 'package:bellezapp/controllers/product_controller.dart';
import 'package:bellezapp/controllers/category_controller.dart';
import 'package:bellezapp/controllers/supplier_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductPage({required this.product, super.key});

  @override
  EditProductPageState createState() => EditProductPageState();
}

class EditProductPageState extends State<EditProductPage> {
  final ProductController productController = Get.find<ProductController>();
  final CategoryController categoryController = Get.find<CategoryController>();
  final SupplierController supplierController = Get.find<SupplierController>();
  
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _stockController;
  
  String? _selectedCategoryId;
  String? _selectedSupplierId;
  String? _selectedLocationId;
  File? _newImageFile;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product['name']);
    _descriptionController = TextEditingController(
      text: widget.product['description'] ?? '',
    );
    _purchasePriceController = TextEditingController(
      text: widget.product['purchasePrice']?.toString() ?? '0',
    );
    _salePriceController = TextEditingController(
      text: widget.product['salePrice']?.toString() ?? '0',
    );
    _stockController = TextEditingController(
      text: widget.product['stock']?.toString() ?? '0',
    );
    
    // Extraer IDs de los objetos populados o usar los _id directamente
    _selectedCategoryId = _extractId(widget.product['categoryId']);
    _selectedSupplierId = _extractId(widget.product['supplierId']);
    _selectedLocationId = _extractId(widget.product['locationId']);
  }

  String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map && value.containsKey('_id')) {
      return value['_id'].toString();
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _newImageFile = File(image.path);
      });
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      Get.snackbar('Error', 'Selecciona una categoría');
      return;
    }

    if (_selectedSupplierId == null) {
      Get.snackbar('Error', 'Selecciona un proveedor');
      return;
    }

    final productId = widget.product['_id'].toString();
    final locationId = _selectedLocationId ?? '000000000000000000000001';

    final success = await productController.updateProduct(
      id: productId,
      name: _nameController.text,
      categoryId: _selectedCategoryId!,
      supplierId: _selectedSupplierId!,
      locationId: locationId,
      purchasePrice: double.parse(_purchasePriceController.text),
      salePrice: double.parse(_salePriceController.text),
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      imageFile: _newImageFile,
    );

    if (success) {
      Get.back(); // Volver a la lista de productos
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final productId = widget.product['_id'].toString();
      final success = await productController.deleteProduct(productId);
      
      if (success) {
        Get.back(); // Volver a la lista de productos
      }
    }
  }

  Widget _buildImageSection() {
    final currentImageUrl = widget.product['foto'];
    
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _newImageFile != null
                  ? Image.file(
                      _newImageFile!,
                      fit: BoxFit.cover,
                    )
                  : currentImageUrl != null && currentImageUrl.toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: currentImageUrl.toString(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Error cargando imagen', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Toca para cambiar imagen', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
      appBar: AppBar(
        title: const Text('Editar Producto'),
        backgroundColor: Utils.colorBotones,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteProduct,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Imagen
            _buildImageSection(),
            const SizedBox(height: 24),

            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del producto*',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Categoría
            Obx(() {
              final categories = categoryController.categories;
              return DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Categoría*',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category['_id'].toString(),
                    child: Text(category['name'] ?? 'Sin nombre'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona una categoría';
                  }
                  return null;
                },
              );
            }),
            const SizedBox(height: 16),

            // Proveedor
            Obx(() {
              final suppliers = supplierController.suppliers;
              return DropdownButtonFormField<String>(
                value: _selectedSupplierId,
                decoration: InputDecoration(
                  labelText: 'Proveedor*',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: suppliers.map((supplier) {
                  return DropdownMenuItem(
                    value: supplier['_id'].toString(),
                    child: Text(supplier['name'] ?? 'Sin nombre'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSupplierId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona un proveedor';
                  }
                  return null;
                },
              );
            }),
            const SizedBox(height: 16),

            // Precio de compra y venta en fila
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _purchasePriceController,
                    decoration: InputDecoration(
                      labelText: 'Precio compra*',
                      prefixText: '\$',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Número inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _salePriceController,
                    decoration: InputDecoration(
                      labelText: 'Precio venta*',
                      prefixText: '\$',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Número inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock
            TextFormField(
              controller: _stockController,
              decoration: InputDecoration(
                labelText: 'Stock*',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                if (int.tryParse(value) == null) {
                  return 'Número inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Botón actualizar
            Obx(() {
              return ElevatedButton(
                onPressed: productController.isLoading ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Utils.colorBotones,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: productController.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Actualizar Producto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
