import 'package:bellezapp/pages/home_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

class EditCategoryPage extends StatefulWidget {
  final Map<String, dynamic> category;

  const EditCategoryPage({super.key, required this.category});

  @override
  EditCategoryPageState createState() => EditCategoryPageState();
}

class EditCategoryPageState extends State<EditCategoryPage> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _fotoController;
  File? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category['name']);
    _descriptionController =
        TextEditingController(text: widget.category['description']);
    _fotoController = TextEditingController(text: widget.category['foto']);
  }

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
        title: Text('Editar Categoría'),
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Utils.elevatedButtonWithIcon(
                            'Cámara', Utils.colorBotones, () {
                          _pickImage(ImageSource.camera);
                        }, Icons.camera),
                        Utils.elevatedButtonWithIcon(
                            'Galería', Utils.colorBotones, () {
                          _pickImage(ImageSource.gallery);
                        }, Icons.photo_library),
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
              Utils.elevatedButton('Actualizar', Utils.colorBotones, () async {
                if (formKey.currentState?.validate() ?? false) {
                    final updatedCategory = {
                      'id': widget.category['id'],
                      'name': _nameController.text,
                      'description': _descriptionController.text,
                      'foto': _fotoController.text,
                    };

                    // Actualizar en la base de datos local
                    await DatabaseHelper().updateCategory(updatedCategory);

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
