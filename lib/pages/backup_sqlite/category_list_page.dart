import 'package:bellezapp/controllers/category_controller.dart';
import 'package:bellezapp/pages/add_category_page_new.dart';
import 'package:bellezapp/pages/edit_category_page_new.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => CategoryListPageState();
}

class CategoryListPageState extends State<CategoryListPage> {
  final CategoryController categoryController = Get.put(CategoryController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    categoryController.loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCategories {
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty) {
      return categoryController.categories;
    }
    
    return categoryController.categories.where((category) {
      final name = (category['name'] ?? '').toString().toLowerCase();
      final description = (category['description'] ?? '').toString().toLowerCase();
      return name.contains(searchText) || description.contains(searchText);
    }).toList();
  }

  Future<void> _deleteCategory(String id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar esta categoría?',
    );
    
    if (confirmed) {
      await categoryController.deleteCategory(id);
    }
  }

  String _getImageUrl(Map<String, dynamic> category) {
    final foto = category['foto'];
    if (foto == null || foto.toString().isEmpty) {
      return '';
    }
    return foto.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: const Text('Categorías'),
        backgroundColor: Utils.colorBotones,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Get.to(() => const AddCategoryPage());
              categoryController.loadCategories();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar categorías...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Lista de categorías
          Expanded(
            child: Obx(() {
              if (categoryController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final categories = _filteredCategories;

              if (categories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, 
                        size: 80, 
                        color: Colors.grey[400]
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No hay categorías'
                            : 'No se encontraron categorías',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(category);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final name = category['name'] ?? 'Sin nombre';
    final description = category['description'] ?? '';
    final imageUrl = _getImageUrl(category);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/img/perfume.webp',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 120,
                          ),
                        )
                      : Image.asset(
                          'assets/img/perfume.webp',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 120,
                        ),
                ),
              ),
              // Botones de acción
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit,
                      color: Colors.blue,
                      onTap: () async {
                        await Get.to(() => EditCategoryPage(category: category));
                        categoryController.loadCategories();
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onTap: () => _deleteCategory(category['_id'].toString()),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Información
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
