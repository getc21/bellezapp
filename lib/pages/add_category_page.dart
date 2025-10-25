import 'package:bellezapp/pages/home_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  AddCategoryPageState createState() => AddCategoryPageState();
}

class AddCategoryPageState extends State<AddCategoryPage> {
  final formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fotoController = TextEditingController();
  File? _image;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage != null) {
        final img.Image resizedImage = img.copyResize(
          originalImage,
          height: 300,
        );

        final resizedImageBytes = img.encodeJpg(resizedImage);
        setState(() {
          _image = imageFile;
          _fotoController.text = base64Encode(resizedImageBytes);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: Text('Agregar Categoría'),
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
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cargar imagen',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Utils.elevatedButtonWithIcon('Cámara', Utils.colorBotones, (){
                          _pickImage(ImageSource.camera);
                        }, Icons.camera),
                        Utils.elevatedButtonWithIcon('Galería', Utils.colorBotones, (){
                          _pickImage(ImageSource.gallery);
                        }, Icons.camera),
                      ],
                    ),
                    if (_image != null) ...[
                      SizedBox(height: 10),
                      Image.file(_image!, height: 200),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20),

              Utils.elevatedButton('Guardar',Utils.colorBotones, () async {
                if (formKey.currentState?.validate() ?? false) {
                    final newCategory = {
                      'name': _nameController.text,
                      'description': _descriptionController.text,
                      'foto': _fotoController.text,
                    };

                    // Guardar en la base de datos local
                    await DatabaseHelper().insertCategory(newCategory);

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