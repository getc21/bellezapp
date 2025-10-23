import 'dart:convert';

import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:bellezapp/pages/add_supplier_page.dart';
import 'package:bellezapp/pages/edit_supplier_page.dart';
import 'package:bellezapp/pages/supplier_products_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => SupplierListPageState();
}

class SupplierListPageState extends State<SupplierListPage> {
  List<Map<String, dynamic>> _suppliers = [];
  final dbHelper = DatabaseHelper();
  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  void _loadSuppliers() async {
    final suppliers = await dbHelper.getSuppliers();
    setState(() {
      _suppliers = suppliers;
    });
  }

  void _deleteSupplier(int id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar este proveedor?',
    );
    if (confirmed) {
      await dbHelper.deleteSupplier(id);
      _loadSuppliers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: Utils.colorFondo,
      body: ListView.builder(
        itemCount: _suppliers.length,
        itemBuilder: (context, index) {
          final supplier = _suppliers[index];
          final fotoBase64 = supplier['foto'];
          Uint8List? imageBytes;
          if (fotoBase64.isNotEmpty) {
            try {
              imageBytes = base64Decode(fotoBase64);
            } catch (e) {
              imageBytes = null; // Si ocurre un error, asigna null
            }
          }
          return GestureDetector(
            onTap: () {
              Get.to(SupplierProductsPage(
                supplierId: supplier['id'],
                supplierName: supplier['name'],
              ));
            },
            child: Card(
              color: Utils.colorFondoCards, // Color de fondo del Card
              margin: const EdgeInsets.symmetric(
                  vertical: 8.0, horizontal: 12.0), // Márgenes del Card
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0), // Bordes redondeados
              ),
              elevation: 4, // Sombra para el Card
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 12.0), // Espaciado interno del Card
                child: Row(
                  children: [
                    // Imagen con bordes redondeados
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                          12.0), // Bordes redondeados de la imagen
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/img/perfume.webp',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(
                        width: 16.0), // Espaciado entre la imagen y el texto
                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier['name'] ?? 'Sin datos',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            supplier['contact_name'] ?? 'Sin datos',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Utils.colorTexto,
                            ),
                          ),
                          Text(
                            supplier['contact_email'] ?? 'Sin datos',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Utils.colorTexto,
                            ),
                          ),
                          Text(
                            supplier['contact_phone'] ?? 'Sin datos',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Utils.colorTexto,
                            ),
                          ),
                          Text(
                            supplier['address'] ?? 'Sin datos',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Utils.colorTexto,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Utils.edit, // Color de fondo
                            borderRadius: BorderRadius.only(
                                topRight:
                                    Radius.circular(16)), // Bordes redondeados
                          ), // Espaciado interno
                          child: IconButton(
                            onPressed: () {
                              Get.to(EditSupplierPage(supplier: supplier));
                            },
                            icon: const Icon(Icons.edit),
                            color: Colors.white, // Color del ícono
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Utils.delete,
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(16)),
                          ),
                          child: IconButton(
                            onPressed: () {
                              _deleteSupplier(supplier['id']);
                            },
                            icon: const Icon(Icons.delete),
                            color: Colors.white, // Color del ícono
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () async {
          Get.to(AddSupplierPage());
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    )); // Cerrar Obx
  }
}
