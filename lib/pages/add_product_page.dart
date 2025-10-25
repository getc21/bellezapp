import 'dart:convert';
import 'dart:io';

import 'package:bellezapp/pages/home_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  AddProductPageState createState() => AddProductPageState();
}

class AddProductPageState extends State<AddProductPage> {
  final formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceCompraController = TextEditingController();
  final _priceVentaController = TextEditingController();
  final _weightController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedSupplierId;
  int? _selectedLocationId;
  final _fotoController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _expirityDateController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _locations = [];
  DateTime? _selectedDate;
  File? _image;

  // Método para mostrar el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Fecha inicial
      firstDate: DateTime(2000), // Fecha mínima
      lastDate: DateTime(2100), // Fecha máxima
      locale: const Locale('es', 'ES'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Utils.colorBotones,
            colorScheme: ColorScheme.light(
                primary: Utils.colorBotones, secondary: Utils.colorGnav),
            textTheme: TextTheme(
              headlineMedium: TextStyle(color: Utils.colorTexto),
              bodyMedium: TextStyle(color: Utils.colorTexto),
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ), dialogTheme: DialogThemeData(backgroundColor: Utils.colorFondo),
          ),
          child: child!,
        );
      }, // Idioma en español
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _expirityDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSuppliers();
    _loadLocations();
  }

  void _loadCategories() async {
    final categories = await DatabaseHelper().getCategories();
    setState(() {
      _categories = categories;
    });
  }

  void _loadSuppliers() async {
    final suppliers = await DatabaseHelper().getSuppliers();
    setState(() {
      _suppliers = suppliers;
    });
  }

  void _loadLocations() async {
    final locations = await DatabaseHelper().getLocations();
    setState(() {
      _locations = locations;
    });
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
      appBar: AppBar(
        title: Text('Agregar Producto'),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Utils.colorFondo,
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
              Utils.espacio10,
              TextFormField(
                controller: _descriptionController,
                cursorColor: Utils.colorBotones,
                decoration: InputDecoration(
                    floatingLabelStyle: TextStyle(
                        color: Utils.colorBotones, fontWeight: FontWeight.bold),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Utils.colorBotones, width: 3),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Descripción'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la descripción';
                  }
                  return null;
                },
              ),
              Utils.espacio10,
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
                      'Cargar imagen desde:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Utils.espacio10,
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
                      Utils.espacio10,
                      Image.file(_image!, height: 200),
                    ],
                  ],
                ),
              ),
              Utils.espacio10,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      cursorColor: Utils.colorBotones,
                      decoration: InputDecoration(
                        floatingLabelStyle: TextStyle(
                            color: Utils.colorBotones,
                            fontWeight: FontWeight.bold),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Utils.colorBotones, width: 3),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        labelText: 'Tamaño',
                      ),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el peso';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stockQuantityController,
                      cursorColor: Utils.colorBotones,
                      decoration: InputDecoration(
                        floatingLabelStyle: TextStyle(
                            color: Utils.colorBotones,
                            fontWeight: FontWeight.bold),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Utils.colorBotones, width: 3),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        labelText: 'Stock',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese la cantidad en stock';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              Utils.espacio10,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCompraController,
                      cursorColor: Utils.colorBotones,
                      decoration: InputDecoration(
                        floatingLabelStyle: TextStyle(
                            color: Utils.colorBotones,
                            fontWeight: FontWeight.bold),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Utils.colorBotones, width: 3),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        labelText: 'Precio de compra',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el precio de compra';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _priceVentaController,
                      cursorColor: Utils.colorBotones,
                      decoration: InputDecoration(
                        floatingLabelStyle: TextStyle(
                            color: Utils.colorBotones,
                            fontWeight: FontWeight.bold),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Utils.colorBotones, width: 3),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        labelText: 'Precio de venta',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el precio de venta';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              Utils.espacio10,
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: InputDecoration(
                    floatingLabelStyle: TextStyle(
                        color: Utils.colorBotones, fontWeight: FontWeight.bold),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Utils.colorBotones, width: 3),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Categoría'),
                items: _categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione una categoría';
                  }
                  return null;
                },
              ),
              Utils.espacio10,
              DropdownButtonFormField<int>(
                initialValue: _selectedSupplierId,
                decoration: InputDecoration(
                    floatingLabelStyle: TextStyle(
                        color: Utils.colorBotones, fontWeight: FontWeight.bold),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Utils.colorBotones, width: 3),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Proveedor'),
                items: _suppliers.map((supplier) {
                  return DropdownMenuItem<int>(
                    value: supplier['id'],
                    child: Text(supplier['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSupplierId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione un proveedor';
                  }
                  return null;
                },
              ),
              Utils.espacio10,
              DropdownButtonFormField<int>(
                initialValue: _selectedLocationId,
                decoration: InputDecoration(
                    floatingLabelStyle: TextStyle(
                        color: Utils.colorBotones, fontWeight: FontWeight.bold),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Utils.colorBotones, width: 3),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Ubicación'),
                items: _locations.map((location) {
                  return DropdownMenuItem<int>(
                    value: location['id'],
                    child: Text(location['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocationId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione un proveedor';
                  }
                  return null;
                },
              ),
              Utils.espacio10,
              TextFormField(
                controller: _expirityDateController,
                cursorColor: Utils.colorBotones,
                decoration: InputDecoration(
                    floatingLabelStyle: TextStyle(
                        color: Utils.colorBotones, fontWeight: FontWeight.bold),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Utils.colorBotones, width: 3),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Fecha de vencimiento'),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la fecha de vencimiento';
                  }
                  return null;
                },
                onTap: () async {
                  await _selectDate(context);
                },
              ),
              SizedBox(height: 20),
              Utils.elevatedButton('Guardar', Utils.colorBotones, () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newProduct = {
                    'name': _nameController.text,
                    'description': _descriptionController.text,
                    'purchase_price': double.parse(_priceCompraController.text),
                    'sale_price': double.parse(_priceVentaController.text),
                    'weight': _weightController.text,
                    'category_id': _selectedCategoryId,
                    'supplier_id': _selectedSupplierId,
                    'stock': int.parse(_stockQuantityController.text),
                    'location_id': _selectedLocationId,
                    'expirity_date': _expirityDateController.text,
                    'foto': _fotoController.text,
                  };

                  // Guardar en la base de datos local
                  await DatabaseHelper().insertProduct(newProduct);

                  Get.to(HomePage()); // Cerrar el diálogo
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}
