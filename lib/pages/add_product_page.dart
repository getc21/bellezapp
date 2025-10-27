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
        title: Row(
          children: [
            Icon(Icons.add_shopping_cart),
            SizedBox(width: 8),
            Text('Nuevo Producto'),
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
              // Sección: Información Básica
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Utils.colorBotones, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Información Básica',
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
                  prefixIcon: Icon(Icons.label, color: Utils.colorBotones),
                  floatingLabelStyle: TextStyle(
                      color: Utils.colorBotones, fontWeight: FontWeight.bold),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Utils.colorBotones, width: 3),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  labelText: 'Nombre del Producto',
                  hintText: 'Ej: Shampoo Dove 400ml',
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
                      borderSide:
                          BorderSide(color: Utils.colorBotones, width: 3),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Descripción',
                    hintText: 'Describe el producto brevemente...'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la descripción';
                  }
                  return null;
                },
              ),
              Utils.espacio10,
              // Sección: Imagen del Producto
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.photo_camera, color: Utils.colorBotones, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Imagen del Producto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Utils.colorBotones,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Utils.colorBotones.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_image == null) ...[
                      Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'Selecciona una foto del producto',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ] else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_image!, height: 200, fit: BoxFit.cover),
                      ),
                    ],
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Utils.elevatedButtonWithIcon(
                              'Cámara', Utils.colorBotones, () {
                            _pickImage(ImageSource.camera);
                          }, Icons.camera_alt),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Utils.elevatedButtonWithIcon(
                              'Galería', Utils.colorBotones, () {
                            _pickImage(ImageSource.gallery);
                          }, Icons.photo_library),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Utils.espacio10,
              // Sección: Detalles y Stock
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.inventory, color: Utils.colorBotones, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Detalles y Stock',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Utils.colorBotones,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      cursorColor: Utils.colorBotones,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.straighten, color: Utils.colorBotones),
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
                        labelText: 'Tamaño/Peso',
                        hintText: '500ml, 250g...',
                      ),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
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
                        prefixIcon: Icon(Icons.inventory_2, color: Utils.colorBotones),
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
                        labelText: 'Stock Inicial',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              Utils.espacio10,
              // Sección: Precios
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: Utils.colorBotones, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Precios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Utils.colorBotones,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCompraController,
                      cursorColor: Utils.colorBotones,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.shopping_cart, color: Colors.orange),
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
                        labelText: 'Precio de Compra',
                        hintText: '\$0.00',
                        helperText: 'Costo del proveedor',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
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
                        prefixIcon: Icon(Icons.sell, color: Colors.green),
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
                        labelText: 'Precio de Venta',
                        hintText: '\$0.00',
                        helperText: 'Precio al público',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              Utils.espacio10,
              // Sección: Clasificación
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.category, color: Utils.colorBotones, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Clasificación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Utils.colorBotones,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined, color: Utils.colorBotones),
                          floatingLabelStyle: TextStyle(
                              color: Utils.colorBotones, fontWeight: FontWeight.bold),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Utils.colorBotones, width: 3),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          labelText: 'Categoría',
                          hintText: _categories.isEmpty ? 'No hay categorías disponibles' : 'Selecciona una categoría'),
                      items: _categories.isEmpty
                          ? null
                          : _categories.map((category) {
                              return DropdownMenuItem<int>(
                                value: category['id'],
                                child: Text(category['name']),
                              );
                            }).toList(),
                      onChanged: _categories.isEmpty ? null : (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) {
                        if (_categories.isEmpty) {
                          return 'Crea una categoría primero';
                        }
                        if (value == null) {
                          return 'Seleccione una categoría';
                        }
                        return null;
                      },
                      disabledHint: Text(
                        'No hay categorías',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Utils.colorBotones,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.white, size: 28),
                      tooltip: 'Crear nueva categoría',
                      onPressed: () => _showCreateCategoryDialog(),
                    ),
                  ),
                ],
              ),
              Utils.espacio10,
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedSupplierId,
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.local_shipping, color: Utils.colorBotones),
                          floatingLabelStyle: TextStyle(
                              color: Utils.colorBotones, fontWeight: FontWeight.bold),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Utils.colorBotones, width: 3),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          labelText: 'Proveedor',
                          hintText: _suppliers.isEmpty ? 'No hay proveedores disponibles' : 'Selecciona un proveedor'),
                      items: _suppliers.isEmpty
                          ? null
                          : _suppliers.map((supplier) {
                              return DropdownMenuItem<int>(
                                value: supplier['id'],
                                child: Text(supplier['name']),
                              );
                            }).toList(),
                      onChanged: _suppliers.isEmpty ? null : (value) {
                        setState(() {
                          _selectedSupplierId = value;
                        });
                      },
                      validator: (value) {
                        if (_suppliers.isEmpty) {
                          return 'Crea un proveedor primero';
                        }
                        if (value == null) {
                          return 'Seleccione un proveedor';
                        }
                        return null;
                      },
                      disabledHint: Text(
                        'No hay proveedores',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Utils.colorBotones,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.white, size: 28),
                      tooltip: 'Crear nuevo proveedor',
                      onPressed: () => _showCreateSupplierDialog(),
                    ),
                  ),
                ],
              ),
              Utils.espacio10,
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedLocationId,
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.place, color: Utils.colorBotones),
                          floatingLabelStyle: TextStyle(
                              color: Utils.colorBotones, fontWeight: FontWeight.bold),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Utils.colorBotones, width: 3),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          labelText: 'Ubicación en Tienda',
                          hintText: _locations.isEmpty ? 'No hay ubicaciones disponibles' : 'Selecciona una ubicación'),
                      items: _locations.isEmpty
                          ? null
                          : _locations.map((location) {
                              return DropdownMenuItem<int>(
                                value: location['id'],
                                child: Text(location['name']),
                              );
                            }).toList(),
                      onChanged: _locations.isEmpty ? null : (value) {
                        setState(() {
                          _selectedLocationId = value;
                        });
                      },
                      validator: (value) {
                        if (_locations.isEmpty) {
                          return 'Crea una ubicación primero';
                        }
                        if (value == null) {
                          return 'Seleccione una ubicación';
                        }
                        return null;
                      },
                      disabledHint: Text(
                        'No hay ubicaciones',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Utils.colorBotones,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.white, size: 28),
                      tooltip: 'Crear nueva ubicación',
                      onPressed: () => _showCreateLocationDialog(),
                    ),
                  ),
                ],
              ),
              Utils.espacio10,
              // Sección: Fecha de Vencimiento
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.event, color: Utils.colorBotones, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Fecha de Vencimiento',
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
                controller: _expirityDateController,
                cursorColor: Utils.colorBotones,
                readOnly: true,
                decoration: InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today, color: Utils.colorBotones),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                    floatingLabelStyle: TextStyle(
                        color: Utils.colorBotones, fontWeight: FontWeight.bold),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Utils.colorBotones, width: 3),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Fecha de vencimiento',
                    hintText: 'Selecciona una fecha'),
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
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
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

                      await DatabaseHelper().insertProduct(newProduct);

                      Get.snackbar(
                        '✓ Éxito',
                        'Producto guardado correctamente',
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
                    'Guardar Producto',
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

  // Método para mostrar diálogo de creación de categoría
  void _showCreateCategoryDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _fotoController = TextEditingController();
    File? _dialogImage;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.category, color: Utils.colorBotones),
                SizedBox(width: 8),
                Text('Nueva Categoría'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: Shampoos',
                        prefixIcon: Icon(Icons.label),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'Descripción de la categoría',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    // Sección de imagen
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (_dialogImage == null) ...[
                            Icon(Icons.image, size: 48, color: Colors.grey[400]),
                            SizedBox(height: 8),
                            Text(
                              'Imagen (opcional)',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ] else ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_dialogImage!, height: 120, fit: BoxFit.cover),
                            ),
                          ],
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(source: ImageSource.camera);
                                    if (pickedFile != null) {
                                      final imageFile = File(pickedFile.path);
                                      final imageBytes = await imageFile.readAsBytes();
                                      final img.Image? originalImage = img.decodeImage(imageBytes);
                                      if (originalImage != null) {
                                        final img.Image resizedImage = img.copyResize(originalImage, height: 300);
                                        final resizedImageBytes = img.encodeJpg(resizedImage);
                                        setDialogState(() {
                                          _dialogImage = imageFile;
                                          _fotoController.text = base64Encode(resizedImageBytes);
                                        });
                                      }
                                    }
                                  },
                                  icon: Icon(Icons.camera_alt, size: 18),
                                  label: Text('Cámara', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                    if (pickedFile != null) {
                                      final imageFile = File(pickedFile.path);
                                      final imageBytes = await imageFile.readAsBytes();
                                      final img.Image? originalImage = img.decodeImage(imageBytes);
                                      if (originalImage != null) {
                                        final img.Image resizedImage = img.copyResize(originalImage, height: 300);
                                        final resizedImageBytes = img.encodeJpg(resizedImage);
                                        setDialogState(() {
                                          _dialogImage = imageFile;
                                          _fotoController.text = base64Encode(resizedImageBytes);
                                        });
                                      }
                                    }
                                  },
                                  icon: Icon(Icons.photo_library, size: 18),
                                  label: Text('Galería', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final newCategory = {
                      'name': _nameController.text,
                      'description': _descriptionController.text,
                      'foto': _fotoController.text,
                    };

                    await DatabaseHelper().insertCategory(newCategory);
                    _loadCategories();
                    
                    Get.back();
                    Get.snackbar(
                      '✓ Éxito',
                      'Categoría creada correctamente',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      duration: Duration(seconds: 2),
                    );
                  }
                },
                icon: Icon(Icons.save),
                label: Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Utils.colorBotones,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Método para mostrar diálogo de creación de proveedor
  void _showCreateSupplierDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _contactNameController = TextEditingController();
    final _contactEmailController = TextEditingController();
    final _contactPhoneController = TextEditingController();
    final _addressController = TextEditingController();
    final _fotoController = TextEditingController();
    File? _dialogImage;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.business, color: Utils.colorBotones),
                SizedBox(width: 8),
                Text('Nuevo Proveedor'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: Distribuidora XYZ',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _contactNameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de contacto (opcional)',
                        hintText: 'Ej: Juan Pérez',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _contactEmailController,
                      decoration: InputDecoration(
                        labelText: 'Email (opcional)',
                        hintText: 'ejemplo@correo.com',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _contactPhoneController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono (opcional)',
                        hintText: '123-456-7890',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Dirección (opcional)',
                        hintText: 'Dirección del proveedor',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    // Sección de imagen
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (_dialogImage == null) ...[
                            Icon(Icons.image, size: 48, color: Colors.grey[400]),
                            SizedBox(height: 8),
                            Text(
                              'Logo/Imagen (opcional)',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ] else ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_dialogImage!, height: 120, fit: BoxFit.cover),
                            ),
                          ],
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(source: ImageSource.camera);
                                    if (pickedFile != null) {
                                      final imageFile = File(pickedFile.path);
                                      final imageBytes = await imageFile.readAsBytes();
                                      final img.Image? originalImage = img.decodeImage(imageBytes);
                                      if (originalImage != null) {
                                        final img.Image resizedImage = img.copyResize(originalImage, height: 300);
                                        final resizedImageBytes = img.encodeJpg(resizedImage);
                                        setDialogState(() {
                                          _dialogImage = imageFile;
                                          _fotoController.text = base64Encode(resizedImageBytes);
                                        });
                                      }
                                    }
                                  },
                                  icon: Icon(Icons.camera_alt, size: 18),
                                  label: Text('Cámara', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                    if (pickedFile != null) {
                                      final imageFile = File(pickedFile.path);
                                      final imageBytes = await imageFile.readAsBytes();
                                      final img.Image? originalImage = img.decodeImage(imageBytes);
                                      if (originalImage != null) {
                                        final img.Image resizedImage = img.copyResize(originalImage, height: 300);
                                        final resizedImageBytes = img.encodeJpg(resizedImage);
                                        setDialogState(() {
                                          _dialogImage = imageFile;
                                          _fotoController.text = base64Encode(resizedImageBytes);
                                        });
                                      }
                                    }
                                  },
                                  icon: Icon(Icons.photo_library, size: 18),
                                  label: Text('Galería', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final newSupplier = {
                      'foto': _fotoController.text,
                      'name': _nameController.text,
                      'contact_name': _contactNameController.text,
                      'contact_email': _contactEmailController.text,
                      'contact_phone': _contactPhoneController.text,
                      'address': _addressController.text,
                    };

                    await DatabaseHelper().insertSupplier(newSupplier);
                    _loadSuppliers();
                    
                    Get.back();
                    Get.snackbar(
                      '✓ Éxito',
                      'Proveedor creado correctamente',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      duration: Duration(seconds: 2),
                    );
                  }
                },
                icon: Icon(Icons.save),
                label: Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Utils.colorBotones,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Método para mostrar diálogo de creación de ubicación
  void _showCreateLocationDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.place, color: Utils.colorBotones),
            SizedBox(width: 8),
            Text('Nueva Ubicación'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Estante A1',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Descripción de la ubicación',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final newLocation = {
                  'name': _nameController.text,
                  'description': _descriptionController.text,
                };

                await DatabaseHelper().insertLocation(newLocation);
                _loadLocations();
                
                Get.back();
                Get.snackbar(
                  '✓ Éxito',
                  'Ubicación creada correctamente',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: Duration(seconds: 2),
                );
              }
            },
            icon: Icon(Icons.save),
            label: Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Utils.colorBotones,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
