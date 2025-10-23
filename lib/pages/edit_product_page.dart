import 'package:bellezapp/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:get/get.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:io';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductPage({required this.product, super.key});

  @override
  EditProductPageState createState() => EditProductPageState();
}

class EditProductPageState extends State<EditProductPage> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceCompraController;
  late TextEditingController _priceVentaController;
  late TextEditingController _weightController;
  late TextEditingController _stockQuantityController;
  late TextEditingController _expirityDateController;
  late TextEditingController _fotoController;
  int? _selectedCategoryId;
  int? _selectedSupplierId;
  int? _selectedLocationId;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _locations = [];
  DateTime? _selectedDate;
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSuppliers();
    _loadLocations();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product['name']);
    _descriptionController =
        TextEditingController(text: widget.product['description']);
    _priceCompraController = TextEditingController(
        text: widget.product['purchase_price'].toString());
    _priceVentaController =
        TextEditingController(text: widget.product['sale_price'].toString());
    _weightController = TextEditingController(text: widget.product['weight']);
    _stockQuantityController =
        TextEditingController(text: widget.product['stock'].toString());
    _expirityDateController =
        TextEditingController(text: widget.product['expirity_date']);
    _fotoController = TextEditingController(text: widget.product['foto']);
    _selectedCategoryId = widget.product['category_id'];
    _selectedSupplierId = widget.product['supplier_id'];
    _selectedLocationId = widget.product['location_id'];
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

  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context)
        .requestFocus(FocusNode()); // Evita que el teclado se abra
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(widget.product['expirity_date']) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            dialogTheme: DialogThemeData(
              backgroundColor: Utils.colorFondo,
            ),
            primaryColor: Utils.colorBotones,
            colorScheme: ColorScheme.light(
                primary: Utils.colorBotones, secondary: Utils.colorGnav),
            textTheme: TextTheme(
              headlineMedium: TextStyle(color: Utils.colorTexto),
              bodyMedium: TextStyle(color: Utils.colorTexto),
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _expirityDateController.text =
            "${pickedDate.toLocal()}".split(' ')[0]; // Formatea la fecha
      });
    }
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
        title: Text('Editar Producto'),
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
              Utils.espacio10,
              TextFormField(
                controller: _descriptionController,
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
                  labelText: 'Descripción',
                ),
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
                      'Cargar imagen',
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
                        }, Icons.photo_library)
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
                          return 'Por favor ingrese el precio';
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
                          return 'Por favor ingrese el precio';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(children: [
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
                      labelText: 'Peso',
                    ),
                    keyboardType: TextInputType.number,
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
              ]),
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
                    return 'Por favor seleccione una ubicación';
                  }
                  return null;
                },
              ),
              Utils.espacio10,
              TextFormField(
                controller: _expirityDateController,
                cursorColor: Utils.colorBotones,
                decoration: InputDecoration(
                    prefixIconColor: Utils.colorBotones,
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
                  final updatedProduct = {
                    'id': widget.product['id'],
                    'name': _nameController.text,
                    'description': _descriptionController.text,
                    'purchase_price': double.parse(_priceCompraController.text),
                    'sale_price': double.parse(_priceVentaController.text),
                    'weight': _weightController.text,
                    'category_id': _selectedCategoryId,
                    'supplier_id': _selectedSupplierId,
                    'location_id': _selectedLocationId,
                    'stock': int.parse(_stockQuantityController.text),
                    'expirity_date': _expirityDateController.text,
                    'foto': _fotoController.text,
                  };

                  // Actualizar en la base de datos local
                  await DatabaseHelper().updateProduct(updatedProduct);

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
