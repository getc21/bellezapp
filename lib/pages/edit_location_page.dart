import 'package:bellezapp/controllers/location_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditLocationPage extends StatefulWidget {
  final Map<String, dynamic> location;

  const EditLocationPage({required this.location, super.key});

  @override
  EditLocationPageState createState() => EditLocationPageState();
}

class EditLocationPageState extends State<EditLocationPage> {
  late final LocationController locationController;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    // Usar la misma instancia del controlador que ya existe
    try {
      locationController = Get.find<LocationController>();
    } catch (e) {
      locationController = Get.put(LocationController());
    }
    _nameController = TextEditingController(text: widget.location['name']);
    _descriptionController = TextEditingController(
      text: widget.location['description'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateLocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    print('🔄 Iniciando actualización de ubicación...');

    final locationId = widget.location['_id'].toString();
    final success = await locationController.updateLocation(
      id: locationId,
      name: _nameController.text,
      description: _descriptionController.text.isEmpty 
          ? null 
          : _descriptionController.text,
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
            'Ubicación actualizada correctamente',
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

  Future<void> _deleteLocation() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta ubicación?'),
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
      print('🗑️ Iniciando eliminación de ubicación...');
      
      final locationId = widget.location['_id'].toString();
      final success = await locationController.deleteLocation(locationId);
      
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
              'Ubicación eliminada correctamente',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.location_on, size: 24),
            SizedBox(width: 8),
            Text('Editar Ubicación'),
          ],
        ),
        backgroundColor: Utils.colorBotones,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteLocation,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Utils.colorBotones, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Información de la Ubicación',
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

            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la ubicación*',
                prefixIcon: Icon(Icons.label, color: Utils.colorBotones),
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
                prefixIcon: Icon(Icons.description, color: Utils.colorBotones),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Botón actualizar
            Obx(() {
              return ElevatedButton(
                onPressed: locationController.isLoading ? null : _updateLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Utils.colorBotones,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: locationController.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Actualizar Ubicación',
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
