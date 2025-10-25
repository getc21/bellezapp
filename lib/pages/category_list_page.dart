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
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => CategoryListPageState();
}

class CategoryListPageState extends State<CategoryListPage> {
  final RxList<Map<String, dynamic>> _categories = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _filteredCategories = <Map<String, dynamic>>[].obs;
  final TextEditingController _searchController = TextEditingController();
  final dbHelper = DatabaseHelper();
  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCategories() async {
    final categories = await dbHelper.getCategories();
    _categories.value = categories;
    _filteredCategories.value = categories;
  }

  void _filterCategories(String searchText) {
    if (searchText.isEmpty) {
      _filteredCategories.value = List.from(_categories);
    } else {
      _filteredCategories.value = _categories.where((category) {
        final name = (category['name'] ?? '').toString().toLowerCase();
        final description = (category['description'] ?? '').toString().toLowerCase();
        final searchLower = searchText.toLowerCase();
        return name.contains(searchLower) || description.contains(searchLower);
      }).toList();
    }
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

  Widget _buildCompactActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: Utils.colorFondo,
      body: Column(
        children: [
          // Header mejorado con búsqueda
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo de búsqueda prominente
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterCategories,
                    decoration: InputDecoration(
                      hintText: 'Buscar categorías...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Utils.colorBotones),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _filterCategories('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Header con contador
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Utils.colorBotones.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_filteredCategories.length} categorías',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Utils.colorBotones,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
              ],
            ),
          ),
          // Lista de categorías
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
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
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Utils.colorFondoCards,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Get.to(CategoryProductsPage(
                          categoryId: category['id'],
                          categoryName: category['name'],
                        ));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Imagen de la categoría
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageBytes != null
                                    ? Image.memory(
                                        imageBytes,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/img/perfume.webp',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            SizedBox(width: 16),
                            // Contenido de la categoría
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Título
                                  Text(
                                    category['name'] ?? 'Sin nombre',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Utils.colorGnav,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  // Descripción
                                  Text(
                                    category['description'] ?? 'Sin descripción',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 12),
                                  // Indicador de navegación
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: Utils.colorBotones,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ver productos',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Utils.colorBotones,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Botones de acción
                            Column(
                              children: [
                                _buildCompactActionButton(
                                  icon: Icons.edit,
                                  color: Utils.edit,
                                  onTap: () => Get.to(EditCategoryPage(category: category)),
                                  tooltip: 'Editar categoría',
                                ),
                                SizedBox(height: 8),
                                _buildCompactActionButton(
                                  icon: Icons.delete,
                                  color: Utils.delete,
                                  onTap: () => _deleteCategory(category['id']),
                                  tooltip: 'Eliminar categoría',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () async {
          final result = await Get.to(AddCategoryPage());
          if (result != null) {
            _loadCategories();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    ));
  }
}
