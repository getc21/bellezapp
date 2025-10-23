import 'package:bellezapp/pages/home_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:get/get.dart';

class EditLocationPage extends StatefulWidget {
  final Map<String, dynamic> location;

  const EditLocationPage({super.key, required this.location});

  @override
  EditLocationPageState createState() => EditLocationPageState();
}

class EditLocationPageState extends State<EditLocationPage> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location['name']);
    _descriptionController = TextEditingController(text: widget.location['description']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: Text('Editar Ubicación'),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                cursorColor: Utils.colorBotones,
                decoration: InputDecoration(
                  prefixIconColor: Utils.colorBotones,
                  floatingLabelStyle: TextStyle(
                      color: Utils.colorBotones, fontWeight: FontWeight.bold),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Utils.colorBotones, width: 3),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  labelText: 'Nombre',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                cursorColor: Utils.colorBotones,
                decoration: InputDecoration(
                  prefixIconColor: Utils.colorBotones,
                  floatingLabelStyle: TextStyle(
                      color: Utils.colorBotones, fontWeight: FontWeight.bold),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Utils.colorBotones, width: 3),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  labelText: 'Descripción',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la descripción';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Utils.elevatedButton('Actualizar', Utils.colorBotones, () async {
                if (formKey.currentState?.validate() ?? false) {
                    final updatedLocation = {
                      'id': widget.location['id'],
                      'name': _nameController.text,
                      'description': _descriptionController.text,
                    };

                    // Actualizar en la base de datos local
                    await DatabaseHelper().updateLocation(updatedLocation);

                    Get.to(HomePage()); // Cerrar la página
                  }
              }),
            ],
          ),
        ),
      ),
    );
  }
}