import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/store.dart';
import '../utils/utils.dart';
import 'add_store_page.dart';

class StoreListPage extends StatefulWidget {
  @override
  _StoreListPageState createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  final StoreController storeController = Get.put(StoreController());
  final ThemeController themeController = Get.find<ThemeController>();
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Utils.colorGnav,
        title: Text('Gestión de Tiendas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => storeController.refresh(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => AddStorePage());
        },
        backgroundColor: Utils.colorBotones,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Agregar Tienda',
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar tiendas...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Obx(() => storeController.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          storeController.clearSearch();
                        },
                      )
                    : SizedBox.shrink()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Utils.colorFondoCards,
              ),
              onChanged: (value) => storeController.searchStores(value),
            ),
          ),
          
          // Estadísticas
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    storeController.totalStores.toString(),
                    Icons.store,
                    Utils.colorGnav,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Activas',
                    storeController.activeStoresCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Inactivas',
                    storeController.inactiveStoresCount.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            )),
          ),
          
          SizedBox(height: 16),
          
          // Lista de tiendas
          Expanded(
            child: Obx(() {
              if (storeController.isLoading) {
                return Center(child: Utils.loadingCustom());
              }
              
              if (storeController.filteredStores.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        storeController.searchQuery.isEmpty
                            ? 'No hay tiendas registradas'
                            : 'No se encontraron tiendas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () => storeController.refresh(),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: storeController.filteredStores.length,
                  itemBuilder: (context, index) {
                    final store = storeController.filteredStores[index];
                    return _buildStoreCard(store);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Utils.colorFondoCards,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Store store) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Utils.colorFondoCards,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              store.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: store.isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              store.isActive ? 'ACTIVA' : 'INACTIVA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            'Código: ${store.code}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, store),
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            store.isActive ? Icons.cancel : Icons.check_circle,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(store.isActive ? 'Desactivar' : 'Activar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Dirección
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    store.address,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            if (store.phone != null && store.phone!.isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    store.phone!,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            
            if (store.email != null && store.email!.isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    store.email!,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            
            if (store.manager != null && store.manager!.isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Encargado: ${store.manager}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Store store) {
    switch (action) {
      case 'edit':
        Get.to(() => AddStorePage(store: store));
        break;
      case 'toggle':
        _showToggleStatusDialog(store);
        break;
      case 'delete':
        _showDeleteDialog(store);
        break;
    }
  }

  void _showToggleStatusDialog(Store store) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Utils.colorFondoCards,
        title: Text('${store.isActive ? 'Desactivar' : 'Activar'} Tienda'),
        content: Text(
          '¿Está seguro que desea ${store.isActive ? 'desactivar' : 'activar'} la tienda "${store.name}"?',
        ),
        actions: [
          Utils.elevatedButton('Cancelar', Utils.no, () {
            Get.back();
          }),
          Utils.elevatedButton('Confirmar', Utils.yes, () async {
            Get.back();
            await storeController.toggleStoreStatus(store.id!);
          }),
        ],
      ),
    );
  }

  void _showDeleteDialog(Store store) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Utils.colorFondoCards,
        title: Text('Eliminar Tienda'),
        content: Text(
          '¿Está seguro que desea eliminar la tienda "${store.name}"?\n\nEsta acción desactivará la tienda.',
        ),
        actions: [
          Utils.elevatedButton('Cancelar', Utils.no, () {
            Get.back();
          }),
          Utils.elevatedButton('Eliminar', Utils.yes, () async {
            Get.back();
            await storeController.deleteStore(store.id!);
          }),
        ],
      ),
    );
  }
}