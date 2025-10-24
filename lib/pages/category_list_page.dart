import 'dart:convert';

import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/controllers/category_controller.dart';
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
  final themeController = Get.find<ThemeController>();
  final categoryController = Get.find<CategoryController>();

  @override
  void initState() {
    super.initState();
    // Ya no necesitamos cargar categorías aquí, el controller lo maneja
  }

  void _deleteCategory(int id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar esta categoría?',
    );
    if (confirmed) {
      try {
        await categoryController.deleteCategory(id);
      } catch (e) {
        Get.snackbar('Error', 'No se pudo eliminar la categoría: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      body: Obx(() {
        if (categoryController.isLoading) {
          return Center(child: Utils.loadingCustom());
        }
        
        return ListView.builder(
          itemCount: categoryController.categories.length,
          itemBuilder: (context, index) {
            final category = categoryController.categories[index];
            final fotoBase64 = category['foto'] ?? '';

            Uint8List? imageBytes;
            if (fotoBase64.isNotEmpty) {
              try {
                imageBytes = base64Decode(fotoBase64);
              } catch (e) {
                imageBytes = null;
              }
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Utils.colorFondoCards,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                  child: imageBytes == null
                      ? Icon(Icons.category, color: Colors.grey.shade600)
                      : null,
                ),
                title: Utils.textTitle(category['name']),
                subtitle: Utils.textDescription(category['description']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
                        final result = await Get.to(EditCategoryPage(category: category));
                        if (result == true) {
                          categoryController.refreshCategories();
                        }
                      },
                      icon: const Icon(Icons.edit),
                      color: Utils.edit,
                    ),
                    IconButton(
                      onPressed: () {
                        _deleteCategory(category['id']);
                      },
                      icon: const Icon(Icons.delete),
                      color: Utils.delete,
                    ),
                  ],
                ),
                onTap: () {
                  Get.to(CategoryProductsPage(
                    categoryName: category['name'],
                    categoryId: category['id'],
                  ));
                },
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () async {
          final result = await Get.to(AddCategoryPage());
          if (result == true) {
            categoryController.refreshCategories();
          }
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}