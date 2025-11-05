import 'dart:io';
import 'package:bellezapp/controllers/supplier_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditSupplierPage extends StatefulWidget {
  final Map<String, dynamic> supplier;

  const EditSupplierPage({required this.supplier, super.key});

  @override
  EditSupplierPageState createState() => EditSupplierPageState();
}

class EditSupplierPageState extends State<EditSupplierPage> {
  final SupplierController supplierController = Get.find<SupplierController>();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _addressController;
  File? _newImageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier['name']);
    _contactNameController = TextEditingController(
      text: widget.supplier['contactName'] ?? '',
    );
    _contactEmailController = TextEditingController(
      text: widget.supplier['contactEmail'] ?? '',
    );
    _contactPhoneController = TextEditingController(
      text: widget.supplier['contactPhone'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.supplier['address'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
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

  Future<void> _showImageSourceDialog() async {
    await Utils.showImageSourceDialog(
      context,
      onImageSelected: (source) => _pickImage(source),
    );
  }

  Future<void> _updateSupplier() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    print('🔄 Iniciando actualización de proveedor...');

    final supplierId = widget.supplier['_id'].toString();
    final success = await supplierController.updateSupplier(
      id: supplierId,
      name: _nameController.text,
      contactName: _contactNameController.text.isEmpty ? null : _contactNameController.text,
      contactEmail: _contactEmailController.text.isEmpty ? null : _contactEmailController.text,
      contactPhone: _contactPhoneController.text.isEmpty ? null : _contactPhoneController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      imageFile: _newImageFile,
    );

    print('📊 Resultado de la actualización: $success');

    if (success) {
      print('✅ Éxito! Ejecutando Navigator.pop()...');
      
      // Primero navegar de regreso
      if (mounted) {
        Navigator.of(context).pop();
        
        // Mostrar snackbar después de regresar
        Future.delayed(Duration(milliseconds: 300), () {
          Get.snackbar(
            'Éxito',
            'Proveedor actualizado correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green[800],
            duration: Duration(seconds: 2),
          );
        });
      }
    } else {
      print('❌ Error en la actualización, no se ejecuta Navigator.pop()');
    }
  }

  Future<void> _deleteSupplier() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este proveedor?'),
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
      print('🗑️ Iniciando eliminación de proveedor...');
      
      final supplierId = widget.supplier['_id'].toString();
      final success = await supplierController.deleteSupplier(supplierId);
      
      print('📊 Resultado de la eliminación: $success');
      
      if (success) {
        print('✅ Éxito! Ejecutando Navigator.pop()...');
        
        // Primero navegar de regreso
        if (mounted) {
          Navigator.of(context).pop();
          
          // Mostrar snackbar después de regresar
          Future.delayed(Duration(milliseconds: 300), () {
            Get.snackbar(
              'Éxito',
              'Proveedor eliminado correctamente',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red.withOpacity(0.1),
              colorText: Colors.red[800],
              duration: Duration(seconds: 2),
            );
          });
        }
      } else {
        print('❌ Error en la eliminación, no se ejecuta Navigator.pop()');
      }
    }
  }

  Widget _buildImageSection() {
    final currentImageUrl = widget.supplier['foto'];
    final hasImage = _newImageFile != null || 
        (currentImageUrl != null && currentImageUrl.toString().isNotEmpty);
    
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Utils.colorBotones.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: hasImage
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _newImageFile != null
                        ? Image.file(
                            _newImageFile!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: currentImageUrl.toString(),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('Error cargando imagen', 
                                  style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                  ),
                  // Badge "Cambiar"
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Utils.colorBotones,
                            Utils.colorBotones.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Cambiar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Utils.colorBotones.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 48,
                      color: Utils.colorBotones,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Toca para agregar imagen',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JPG, PNG (máx. 1024x1024)',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
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
        title: Row(
          children: const [
            Icon(Icons.business, size: 24),
            SizedBox(width: 8),
            Text('Editar Proveedor'),
          ],
        ),
        backgroundColor: Utils.colorBotones,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteSupplier,
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

            // Información Básica
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Utils.colorBotones, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Información Básica',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Utils.colorBotones
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nombre de la empresa
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la empresa*',
                prefixIcon: Icon(Icons.business, color: Utils.colorBotones,),
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

            // Información de Contacto
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.contact_phone, color: Utils.colorBotones, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Información de Contacto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Utils.colorBotones
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nombre de contacto
            TextFormField(
              controller: _contactNameController,
              decoration: InputDecoration(
                labelText: 'Nombre de contacto',
                prefixIcon: Icon(Icons.person, color: Utils.colorBotones),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Teléfono
            TextFormField(
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone, color: Utils.colorBotones),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _contactEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email, color: Utils.colorBotones),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!GetUtils.isEmail(value)) {
                    return 'Email inválido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dirección
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Dirección',
                prefixIcon: Icon(Icons.location_on, color: Utils.colorBotones),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Botón actualizar
            Obx(() {
              return ElevatedButton(
                onPressed: supplierController.isLoading ? null : _updateSupplier,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Utils.colorBotones,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: supplierController.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Actualizar Proveedor',
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
