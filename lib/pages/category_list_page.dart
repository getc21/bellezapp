import 'dart:convert';

import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:bellezapp/pages/add_category_page.dart';
import 'package:bellezapp/pages/category_products_page.dart';
import 'package:bellezapp/pages/edit_category_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryListPage extends StatefulWidget {
  CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => CategoryListPageState();
}

class CategoryListPageState extends State<CategoryListPage> {
  List<Map<String, dynamic>> _categories = [];
  final dbHelper = DatabaseHelper();
  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    final categories = await dbHelper.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  void _deleteCategory(int id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar esta categoria?',
    );
    if(confirmed){
      await dbHelper.deleteCategory(id);
    _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: Utils.colorFondo,
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final fotoBase64 = category['foto'];
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
              Get.to(CategoryProductsPage(
                categoryId: category['id'],
                categoryName: category['name'],
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
                padding: const EdgeInsets.only(left: 12), // Espaciado interno del Card
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
                              width: 120,
                              fit: BoxFit.fill,
                            )
                          : Image.asset(
                              'assets/img/perfume.webp',
                              height: 80,
                              width: 80,
                              fit: BoxFit.fill,
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
                            category['name'] ?? 'Sin datos',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            category['description'] ?? 'Sin datos',
                            style: TextStyle(
                              fontSize: 14.0,
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
                                  Get.to(EditCategoryPage(category: category));
                                },
                                icon: const Icon(Icons.edit),
                                color: Colors.white, // Color del ícono
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Utils.delete,
                                borderRadius: BorderRadius.only(
                                    bottomRight:
                                        Radius.circular(16)),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  _deleteCategory(category['id']);
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
          Get.to(AddCategoryPage());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    )); // Cerrar Obx
  }
}
