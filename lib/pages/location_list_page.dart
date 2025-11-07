import 'package:bellezapp/controllers/location_controller.dart';
import 'package:bellezapp/pages/add_location_page.dart';
import 'package:bellezapp/pages/edit_location_page.dart';
import 'package:bellezapp/pages/filtered_products_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocationListPage extends StatefulWidget {
  const LocationListPage({super.key});

  @override
  State<LocationListPage> createState() => LocationListPageState();
}

class LocationListPageState extends State<LocationListPage> {
  late final LocationController locationController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Usar la misma instancia del controlador que ya existe
    try {
      locationController = Get.find<LocationController>();
    } catch (e) {
      locationController = Get.put(LocationController());
    }
    _loadLocations();
  }

  void _loadLocations() {
    // Cargar ubicaciones para la tienda actual
    locationController.loadLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredLocations {
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty) {
      return locationController.locations;
    }

    return locationController.locations.where((location) {
      final name = (location['name'] ?? '').toString().toLowerCase();
      final description = (location['description'] ?? '')
          .toString()
          .toLowerCase();
      return name.contains(searchText) || description.contains(searchText);
    }).toList();
  }

  Future<void> _deleteLocation(String id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar esta ubicación?',
    );

    if (confirmed) {
      await locationController.deleteLocation(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      body: Column(
        children: [
          // Header mejorado con búsqueda prominente
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de la sección
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Utils.colorBotones.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.place_rounded,
                        color: Utils.colorBotones,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Ubicaciones',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Campo de búsqueda prominente
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    style: TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Buscar ubicaciones por nombre o descripción...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Utils.colorBotones,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // Contador de ubicaciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Todas las ubicaciones',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Obx(
                      () => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Utils.colorBotones.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_filteredLocations.length} ubicaciones',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Utils.colorBotones,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
              ],
            ),
          ),

          // Lista de ubicaciones
          Expanded(
            child: Obx(() {
              if (locationController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final locations = _filteredLocations;

              if (locations.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: (locations.length / 2).ceil(),
                itemBuilder: (context, rowIndex) {
                  final leftIndex = rowIndex * 2;
                  final rightIndex = leftIndex + 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildLocationCard(locations[leftIndex]),
                          ),
                          if (rightIndex < locations.length) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildLocationCard(locations[rightIndex]),
                            ),
                          ] else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () async {
          final result = await Get.to(() => const AddLocationPage());
          if (result == true || result == null) {
            locationController.loadLocations();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Utils.colorBotones.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchController.text.isEmpty
                  ? Icons.place_outlined
                  : Icons.search_off,
              size: 80,
              color: Utils.colorBotones.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isEmpty
                ? 'No hay ubicaciones'
                : 'No se encontraron ubicaciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Comienza agregando tu primera ubicación'
                : 'Intenta con otros términos de búsqueda',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    final name = location['name'] ?? 'Sin nombre';
    final description = location['description'] ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Navegar a productos filtrados por esta ubicación
        Get.to(
          () => FilteredProductsPage(
            filterType: 'location',
            filterId: location['_id'].toString(),
            filterName: name,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Utils.colorFondoCards,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con ícono grande y gradiente
            Stack(
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Utils.colorBotones.withValues(alpha: 0.1),
                        Utils.colorBotones.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 50,
                      color: Utils.colorBotones,
                    ),
                  ),
                ),

                // Botones de acción en la esquina superior
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactActionButton(
                          icon: Icons.edit_rounded,
                          color: Utils.edit,
                          onTap: () async {
                            final result = await Get.to(
                              () => EditLocationPage(location: location),
                            );
                            if (result == true || result == null) {
                              locationController.loadLocations();
                            }
                          },
                          tooltip: 'Editar',
                        ),
                        const SizedBox(width: 4),
                        _buildCompactActionButton(
                          icon: Icons.delete_rounded,
                          color: Utils.delete,
                          onTap: () =>
                              _deleteLocation(location['_id'].toString()),
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Información
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre con icono
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Utils.colorBotones.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.label_rounded,
                          color: Utils.colorBotones,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              description,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ),
    );
  }
}
