import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:bellezapp/pages/add_location_page.dart';
import 'package:bellezapp/pages/edit_location_page.dart';
import 'package:bellezapp/pages/location_products_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/mixins/store_aware_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocationListPage extends StatefulWidget {
  const LocationListPage({super.key});

  @override
  State<LocationListPage> createState() => LocationListPageState();
}

class LocationListPageState extends State<LocationListPage> with StoreAwareMixin {
  final RxList<Map<String, dynamic>> _locations = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _filteredLocations = <Map<String, dynamic>>[].obs;
  final TextEditingController _searchController = TextEditingController();
  final dbHelper = DatabaseHelper();
  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void reloadData() {
    print('🔄 Recargando ubicaciones por cambio de tienda');
    _loadLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadLocations() async {
    final locations = await dbHelper.getLocations();
    _locations.value = locations;
    _filteredLocations.value = locations;
  }

  void _filterLocations(String searchText) {
    if (searchText.isEmpty) {
      _filteredLocations.value = List.from(_locations);
    } else {
      _filteredLocations.value = _locations.where((location) {
        final name = (location['name'] ?? '').toString().toLowerCase();
        final description = (location['description'] ?? '').toString().toLowerCase();
        final searchLower = searchText.toLowerCase();
        return name.contains(searchLower) || description.contains(searchLower);
      }).toList();
    }
  }

  void _deleteLocation(int id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar esta ubicación?',
    );
    if (confirmed) {
      await dbHelper.deleteLocation(id);
      _loadLocations();
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
                blurRadius: 4,
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
          // Header moderno con búsqueda
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
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterLocations,
                    style: TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar ubicaciones...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: Utils.colorBotones, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _filterLocations('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Header con contador
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ubicaciones',
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
                        '${_filteredLocations.length} ubicaciones',
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
          // Lista de ubicaciones
          Expanded(
            child: _filteredLocations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                final location = _filteredLocations[index];
                
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
                        Get.to(LocationProductsPage(
                          locationId: location['id'],
                          locationName: location['name'],
                        ));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Ícono de ubicación
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Utils.colorBotones.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Utils.colorBotones,
                                size: 32,
                              ),
                            ),
                            SizedBox(width: 16),
                            // Contenido de la ubicación
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nombre de la ubicación
                                  Text(
                                    location['name'] ?? 'Sin nombre',
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
                                    location['description'] ?? 'Sin descripción',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 3,
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
                                  onTap: () => Get.to(EditLocationPage(location: location)),
                                  tooltip: 'Editar ubicación',
                                ),
                                SizedBox(height: 8),
                                _buildCompactActionButton(
                                  icon: Icons.delete,
                                  color: Utils.delete,
                                  onTap: () => _deleteLocation(location['id']),
                                  tooltip: 'Eliminar ubicación',
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
          final result = await Get.to(AddLocationPage());
          if (result != null) {
            _loadLocations();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    ));
  }

  Widget _buildEmptyState() {
    String mensaje;
    
    if (_searchController.text.isNotEmpty) {
      mensaje = 'No se encontraron ubicaciones que coincidan con tu búsqueda.';
    } else {
      mensaje = 'No hay ubicaciones registradas en esta tienda. Agrega tu primera ubicación usando el botón "+".';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Utils.colorBotones.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              size: 80,
              color: Utils.colorBotones,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin Ubicaciones',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Utils.colorTexto,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Utils.colorTexto.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _loadLocations();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Utils.colorBotones,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
