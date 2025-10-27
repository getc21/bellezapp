import 'package:bellezapp/pages/home_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:get/get.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  AddLocationPageState createState() => AddLocationPageState();
}

class AddLocationPageState extends State<AddLocationPage> {
  final formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.location_on, size: 24),
            SizedBox(width: 8),
            Text('Nueva Ubicación'),
          ],
        ),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: Utils.colorFondo,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              // Sección: Información de la Ubicación
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Utils.colorBotones, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Información de la Ubicación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Utils.colorBotones,
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _nameController,
                cursorColor: Utils.colorBotones,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on, color: Utils.colorBotones),
                  floatingLabelStyle: TextStyle(
                      color: Utils.colorBotones, fontWeight: FontWeight.bold),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Utils.colorBotones, width: 3),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  labelText: 'Nombre de la Ubicación',
                  hintText: 'Ej: Estante A1, Almacén Principal, Vitrina...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre';
                  }
                  return null;
                },
              ),
              Utils.espacio10,
              TextFormField(
                controller: _descriptionController,
                cursorColor: Utils.colorBotones,
                maxLines: 3,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.description, color: Utils.colorBotones),
                  floatingLabelStyle: TextStyle(
                      color: Utils.colorBotones, fontWeight: FontWeight.bold),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Utils.colorBotones, width: 3),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  labelText: 'Descripción',
                  hintText: 'Describe las características de esta ubicación...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la descripción';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 24),

              // Botón de guardar destacado
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final newLocation = {
                        'name': _nameController.text,
                        'description': _descriptionController.text,
                      };

                      await DatabaseHelper().insertLocation(newLocation);

                      Get.snackbar(
                        '✓ Éxito',
                        'Ubicación guardada correctamente',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: Duration(seconds: 2),
                      );

                      Get.to(HomePage());
                    }
                  },
                  icon: Icon(Icons.save, size: 24),
                  label: Text(
                    'Guardar Ubicación',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Utils.colorBotones,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}