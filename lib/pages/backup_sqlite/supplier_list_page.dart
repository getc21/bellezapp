import 'dart:convert';

import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:bellezapp/pages/add_supplier_page.dart';
import 'package:bellezapp/pages/edit_supplier_page.dart';
import 'package:bellezapp/pages/supplier_products_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/mixins/store_aware_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => SupplierListPageState();
}

class SupplierListPageState extends State<SupplierListPage> with StoreAwareMixin {
  final RxList<Map<String, dynamic>> _suppliers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _filteredSuppliers = <Map<String, dynamic>>[].obs;
  final TextEditingController _searchController = TextEditingController();
  final dbHelper = DatabaseHelper();
  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void reloadData() {
    print('🔄 Recargando proveedores por cambio de tienda');
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSuppliers() async {
    final suppliers = await dbHelper.getSuppliers();
    _suppliers.value = suppliers;
    _filteredSuppliers.value = suppliers;
  }

  void _filterSuppliers(String searchText) {
    if (searchText.isEmpty) {
      _filteredSuppliers.value = List.from(_suppliers);
    } else {
      _filteredSuppliers.value = _suppliers.where((supplier) {
        final name = (supplier['name'] ?? '').toString().toLowerCase();
        final contactName = (supplier['contact_name'] ?? '').toString().toLowerCase();
        final email = (supplier['contact_email'] ?? '').toString().toLowerCase();
        final phone = (supplier['contact_phone'] ?? '').toString().toLowerCase();
        final address = (supplier['address'] ?? '').toString().toLowerCase();
        final searchLower = searchText.toLowerCase();
        return name.contains(searchLower) ||
               contactName.contains(searchLower) ||
               email.contains(searchLower) ||
               phone.contains(searchLower) ||
               address.contains(searchLower);
      }).toList();
    }
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

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) {
      Get.snackbar(
        'Error',
        'No hay número de teléfono disponible',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final url = 'https://wa.me/591$cleanPhone';
    
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo abrir WhatsApp',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
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
                    onChanged: _filterSuppliers,
                    style: TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar proveedores...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: Utils.colorBotones, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _filterSuppliers('');
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
                      'Proveedores',
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
                        '${_filteredSuppliers.length} proveedores',
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
          // Lista de proveedores
          Expanded(
            child: _filteredSuppliers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSuppliers.length,
              itemBuilder: (context, index) {
                final supplier = _filteredSuppliers[index];
                final fotoBase64 = supplier['foto'] ?? '';
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
                        Get.to(SupplierProductsPage(
                          supplierId: supplier['id'],
                          supplierName: supplier['name'],
                        ));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Imagen del proveedor
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
                            // Contenido del proveedor
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nombre del proveedor
                                  Text(
                                    supplier['name'] ?? 'Sin nombre',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Utils.colorGnav,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  // Información de contacto
                                  if (supplier['contact_name'] != null && supplier['contact_name'].isNotEmpty)
                                    _buildInfoRow(Icons.person, supplier['contact_name']),
                                  if (supplier['contact_email'] != null && supplier['contact_email'].isNotEmpty)
                                    _buildInfoRow(Icons.email, supplier['contact_email']),
                                  if (supplier['contact_phone'] != null && supplier['contact_phone'].isNotEmpty)
                                    _buildInfoRow(Icons.phone, supplier['contact_phone']),
                                  if (supplier['address'] != null && supplier['address'].isNotEmpty)
                                    _buildInfoRow(Icons.location_on, supplier['address']),
                                  SizedBox(height: 8),
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
                                  onTap: () => Get.to(EditSupplierPage(supplier: supplier)),
                                  tooltip: 'Editar proveedor',
                                ),
                                SizedBox(height: 8),
                                _buildCompactActionButton(
                                  icon: Icons.phone,
                                  color: Colors.green,
                                  onTap: () => _launchWhatsApp(supplier['contact_phone']),
                                  tooltip: 'Contactar por WhatsApp',
                                ),
                                SizedBox(height: 8),
                                _buildCompactActionButton(
                                  icon: Icons.delete,
                                  color: Utils.delete,
                                  onTap: () => _deleteSupplier(supplier['id']),
                                  tooltip: 'Eliminar proveedor',
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
          final result = await Get.to(AddSupplierPage());
          if (result != null) {
            _loadSuppliers();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    ));
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[600],
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String mensaje;
    
    if (_searchController.text.isNotEmpty) {
      mensaje = 'No se encontraron proveedores que coincidan con tu búsqueda.';
    } else {
      mensaje = 'No hay proveedores registrados. Agrega tu primer proveedor usando el botón "+".';
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
              Icons.business_outlined,
              size: 80,
              color: Utils.colorBotones,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin Proveedores',
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
              _loadSuppliers();
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
