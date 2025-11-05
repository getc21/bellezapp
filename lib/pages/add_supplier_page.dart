import 'dart:io';
import 'package:bellezapp/controllers/supplier_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AddSupplierPage extends StatefulWidget {
  const AddSupplierPage({super.key});

  @override
  AddSupplierPageState createState() => AddSupplierPageState();
}

class AddSupplierPageState extends State<AddSupplierPage> {
  final SupplierController supplierController = Get.find<SupplierController>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  File? _imageFile;

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
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    await Utils.showImageSourceDialog(
      context,
      onImageSelected: (source) => _pickImage(source),
    );
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    print('🔄 Iniciando guardado de proveedor...');

    final success = await supplierController.createSupplier(
      name: _nameController.text,
      contactName: _contactNameController.text.isEmpty ? null : _contactNameController.text,
      contactEmail: _contactEmailController.text.isEmpty ? null : _contactEmailController.text,
      contactPhone: _contactPhoneController.text.isEmpty ? null : _contactPhoneController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      imageFile: _imageFile,
    );

    print('📊 Resultado del guardado: $success');

    if (success) {
      print('✅ Éxito! Ejecutando Navigator.pop()...');
      
      // Primero navegar de regreso
      if (mounted) {
        Navigator.of(context).pop();
        
        // Mostrar snackbar después de regresar
        Future.delayed(Duration(milliseconds: 300), () {
          Get.snackbar(
            'Éxito',
            'Proveedor creado correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green[800],
            duration: Duration(seconds: 2),
          );
        });
      }
    } else {
      print('❌ Error en el guardado, no se ejecuta Navigator.pop()');
    }
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
            Text('Nuevo Proveedor'),
          ],
        ),
        backgroundColor: Utils.colorBotones,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Imagen
            GestureDetector(
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
                child: _imageFile != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _imageFile!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
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
            ),
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
                prefixIcon: Icon(Icons.business, color: Utils.colorBotones),
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

            // Botón guardar
            Obx(() {
              return ElevatedButton(
                onPressed: supplierController.isLoading ? null : _saveSupplier,
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
                        'Guardar Proveedor',
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
