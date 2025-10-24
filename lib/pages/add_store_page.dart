import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/store.dart';
import '../utils/utils.dart';

class AddStorePage extends StatefulWidget {
  final Store? store;
  
  AddStorePage({this.store});

  @override
  _AddStorePageState createState() => _AddStorePageState();
}

class _AddStorePageState extends State<AddStorePage> {
  final StoreController storeController = Get.find<StoreController>();
  final ThemeController themeController = Get.find<ThemeController>();
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController managerController = TextEditingController();
  
  bool isEditing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isEditing = widget.store != null;
    
    if (isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final store = widget.store!;
    nameController.text = store.name;
    codeController.text = store.code;
    addressController.text = store.address;
    phoneController.text = store.phone ?? '';
    emailController.text = store.email ?? '';
    managerController.text = store.manager ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    managerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Utils.colorGnav,
        title: Text(isEditing ? 'Editar Tienda' : 'Nueva Tienda'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información básica
              _buildSectionTitle('Información Básica'),
              SizedBox(height: 16),
              
              _buildTextField(
                controller: nameController,
                label: 'Nombre de la Tienda',
                hint: 'Ej: Tienda Principal',
                icon: Icons.store,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (value.trim().length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              _buildTextField(
                controller: codeController,
                label: 'Código de Tienda',
                hint: 'Ej: MAIN, NORTE',
                icon: Icons.qr_code,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El código es obligatorio';
                  }
                  if (value.trim().length < 2) {
                    return 'El código debe tener al menos 2 caracteres';
                  }
                  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value.trim().toUpperCase())) {
                    return 'Solo se permiten letras mayúsculas y números';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              _buildTextField(
                controller: addressController,
                label: 'Dirección',
                hint: 'Dirección completa de la tienda',
                icon: Icons.location_on,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La dirección es obligatoria';
                  }
                  if (value.trim().length < 10) {
                    return 'Ingrese una dirección más completa';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 24),
              
              // Información de contacto
              _buildSectionTitle('Información de Contacto'),
              SizedBox(height: 16),
              
              _buildTextField(
                controller: phoneController,
                label: 'Teléfono',
                hint: 'Ej: +1234567890',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length < 8) {
                      return 'Ingrese un número válido';
                    }
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              _buildTextField(
                controller: emailController,
                label: 'Email',
                hint: 'tienda@empresa.com',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!GetUtils.isEmail(value.trim())) {
                      return 'Ingrese un email válido';
                    }
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              _buildTextField(
                controller: managerController,
                label: 'Encargado',
                hint: 'Nombre del encargado de la tienda',
                icon: Icons.person,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length < 2) {
                      return 'El nombre debe tener al menos 2 caracteres';
                    }
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 32),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: Utils.elevatedButton(
                      'Cancelar',
                      Utils.no,
                      () => Get.back(),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Utils.elevatedButton(
                      isEditing ? 'Actualizar' : 'Crear',
                      Utils.yes,
                      isLoading ? () {} : () => _saveStore(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Utils.colorGnav,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Utils.colorFondoCards,
      ),
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
    );
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Validar código único
      final code = codeController.text.trim().toUpperCase();
      final isValidCode = await storeController.isValidStoreCode(
        code,
        excludeId: widget.store?.id,
      );

      if (!isValidCode) {
        Get.snackbar(
          'Error',
          'El código "$code" ya está en uso',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      bool success = false;

      if (isEditing) {
        // Actualizar tienda existente
        final updatedStore = widget.store!.copyWith(
          name: nameController.text.trim(),
          code: code,
          address: addressController.text.trim(),
          phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
          email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
          manager: managerController.text.trim().isNotEmpty ? managerController.text.trim() : null,
          updatedAt: DateTime.now(),
        );
        
        success = await storeController.updateStore(updatedStore);
      } else {
        // Crear nueva tienda
        success = await storeController.createStore(
          name: nameController.text.trim(),
          code: code,
          address: addressController.text.trim(),
          phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
          email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
          manager: managerController.text.trim().isNotEmpty ? managerController.text.trim() : null,
        );
      }

      if (success) {
        // Mostrar mensaje de éxito
        Get.snackbar(
          'Éxito',
          isEditing ? 'Tienda editada correctamente' : 'Tienda creada correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Utils.yes.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        
        // Asegurar que el widget esté montado antes de navegar
        if (mounted) {
          // Programar la navegación después de que el snackbar se muestre
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}