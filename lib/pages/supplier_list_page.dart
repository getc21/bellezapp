import 'package:bellezapp/controllers/supplier_controller.dart';
import 'package:bellezapp/pages/add_supplier_page.dart';
import 'package:bellezapp/pages/edit_supplier_page.dart';
import 'package:bellezapp/pages/filtered_products_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => SupplierListPageState();
}

class SupplierListPageState extends State<SupplierListPage> {
  final SupplierController supplierController = Get.put(SupplierController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    supplierController.loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredSuppliers {
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty) {
      return supplierController.suppliers;
    }
    
    return supplierController.suppliers.where((supplier) {
      final name = (supplier['name'] ?? '').toString().toLowerCase();
      final contactName = (supplier['contactName'] ?? '').toString().toLowerCase();
      final email = (supplier['contactEmail'] ?? '').toString().toLowerCase();
      final phone = (supplier['contactPhone'] ?? '').toString().toLowerCase();
      final address = (supplier['address'] ?? '').toString().toLowerCase();
      return name.contains(searchText) ||
             contactName.contains(searchText) ||
             email.contains(searchText) ||
             phone.contains(searchText) ||
             address.contains(searchText);
    }).toList();
  }

  Future<void> _deleteSupplier(String id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar este proveedor?',
    );
    
    if (confirmed) {
      await supplierController.deleteSupplier(id);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    try {
      // URL para Gmail web con destinatario pre-llenado
      final gmailUrl = 'https://mail.google.com/mail/?view=cm&fs=1&to=$email&su=Contacto%20desde%20BellezApp&body=Hola,%0A%0AMe%20contacto%20contigo%20desde%20BellezApp.%0A%0ASaludos';
      final uri = Uri.parse(gmailUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback al cliente de email predeterminado
        final fallbackUri = Uri.parse('mailto:$email?subject=Contacto desde BellezApp&body=Hola,%0A%0AMe contacto contigo desde BellezApp.%0A%0ASaludos');
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri);
        } else {
          // Si no puede abrir ninguno, mostrar opciones
          _showEmailOptions(email);
        }
      }
    } catch (e) {
      _showEmailOptions(email);
    }
  }

  void _showEmailOptions(String email) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Enviar email',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            
            // Opción Gmail (principal)
            Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDB4437), Color(0xFFE57373)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFDB4437).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.mail, color: Colors.white, size: 24),
                ),
                title: Text(
                  'Abrir Gmail',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Componer email en Gmail',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                onTap: () async {
                  Get.back();
                  final gmailUrl = 'https://mail.google.com/mail/?view=cm&fs=1&to=$email&su=Contacto%20desde%20BellezApp&body=Hola,%0A%0AMe%20contacto%20contigo%20desde%20BellezApp.%0A%0ASaludos';
                  final uri = Uri.parse(gmailUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ),
            
            // Opción email predeterminado
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.email_outlined, color: Colors.orange, size: 24),
                ),
                title: Text(
                  'Otro cliente email',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Abrir con app predeterminada',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  Get.back();
                  final uri = Uri.parse('mailto:$email?subject=Contacto desde BellezApp&body=Hola,%0A%0AMe contacto contigo desde BellezApp.%0A%0ASaludos');
                  await launchUrl(uri);
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(String phone) async {
    try {
      
      // Limpiar el número de teléfono (quitar espacios, guiones, paréntesis, etc.)
      String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Si no empieza con '+', agregar código de país (Colombia +57)
      if (!cleanPhone.startsWith('+')) {
        if (cleanPhone.length == 10) {
          cleanPhone = '+57$cleanPhone';
        } else if (cleanPhone.length == 12 && cleanPhone.startsWith('57')) {
          cleanPhone = '+$cleanPhone';
        } else if (cleanPhone.length == 7 || cleanPhone.length == 8) {
          // Números locales cortos, agregar código de área de Bogotá
          cleanPhone = '+571$cleanPhone';
        } else {
          cleanPhone = '+$cleanPhone';
        }
      }
      

      // URL para WhatsApp con mensaje predeterminado
      final whatsappUrl = 'https://wa.me/${cleanPhone.replaceAll('+', '')}?text=${Uri.encodeComponent('Hola, me contacto desde BellezApp')}';      
      final uri = Uri.parse(whatsappUrl);
      
      // Intentar abrir directamente sin verificar canLaunchUrl (a veces da falsos negativos)
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (launchError) {
        
        // Intentar URL alternativa para WhatsApp
        final alternativeUrl = 'whatsapp://send?phone=${cleanPhone.replaceAll('+', '')}&text=${Uri.encodeComponent('Hola, me contacto desde BellezApp')}';
        final alternativeUri = Uri.parse(alternativeUrl);
        
        try {
          await launchUrl(alternativeUri, mode: LaunchMode.externalApplication);
        } catch (alternativeError) {
          _showContactOptions(phone);
        }
      }
    } catch (e) {
      _showContactOptions(phone);
    }
  }

  void _showContactOptions(String phone) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Contactar proveedor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              phone,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            
            // Opción WhatsApp (principal)
            Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF25D366).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chat, color: Colors.white, size: 24),
                ),
                title: Text(
                  'Enviar WhatsApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Mensaje directo por WhatsApp',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                onTap: () {
                  Get.back();
                  _openWhatsApp(phone);
                },
              ),
            ),
            
            // Opción llamar
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.phone, color: Colors.blue, size: 24),
                ),
                title: Text(
                  'Llamar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Llamada telefónica',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Get.back();
                  _makePhoneCall(phone);
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getImageUrl(Map<String, dynamic> supplier) {
    final foto = supplier['foto'];
    if (foto == null || foto.toString().isEmpty) {
      return '';
    }
    return foto.toString();
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
                        Icons.business_rounded,
                        color: Utils.colorBotones,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Proveedores',
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
                      hintText: 'Buscar por nombre, contacto, email, teléfono...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: Utils.colorBotones, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                
                // Contador de proveedores
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Todos los proveedores',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Obx(() => Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Utils.colorBotones.withValues(alpha: 0.1),
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
                    )),
                  ],
                ),
                SizedBox(height: 6),
              ],
            ),
          ),

          // Lista de proveedores
          Expanded(
            child: Obx(() {
              if (supplierController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final suppliers = _filteredSuppliers;

              if (suppliers.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: suppliers.length,
                itemBuilder: (context, index) {
                  final supplier = suppliers[index];
                  return _buildSupplierCard(supplier);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () async {
          final result = await Get.to(() => const AddSupplierPage());
          if (result == true || result == null) {
            supplierController.loadSuppliers();
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
                  ? Icons.business_outlined
                  : Icons.search_off,
              size: 80,
              color: Utils.colorBotones.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isEmpty
                ? 'No hay proveedores'
                : 'No se encontraron proveedores',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Comienza agregando tu primer proveedor'
                : 'Intenta con otros términos de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> supplier) {
    final name = supplier['name'] ?? 'Sin nombre';
    final contactName = supplier['contactName'] ?? '';
    final email = supplier['contactEmail'] ?? '';
    final phone = supplier['contactPhone'] ?? '';
    final address = supplier['address'] ?? '';
    final imageUrl = _getImageUrl(supplier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Cabecera con imagen y acciones
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Imagen con badge
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Utils.colorBotones.withValues(alpha: 0.1),
                            Utils.colorBotones.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Utils.colorBotones.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Utils.colorBotones,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.business,
                                  size: 35,
                                  color: Utils.colorBotones.withValues(alpha: 0.5),
                                ),
                              )
                            : Icon(
                                Icons.business,
                                size: 35,
                                color: Utils.colorBotones.withValues(alpha: 0.5),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.store_rounded,
                            size: 16,
                            color: Utils.colorBotones,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (contactName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                contactName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Botones de acción compactos
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: EdgeInsets.all(4),
                  child: Column(
                    children: [
                      _buildCompactActionButton(
                        icon: Icons.inventory_rounded,
                        color: Utils.colorBotones,
                        onTap: () {
                          // Navegar a productos filtrados por este proveedor
                          Get.to(() => FilteredProductsPage(
                            filterType: 'supplier',
                            filterId: supplier['_id'].toString(),
                            filterName: supplier['name'] ?? 'Sin nombre',
                          ));
                        },
                        tooltip: 'Ver productos',
                      ),
                      const SizedBox(height: 4),
                      _buildCompactActionButton(
                        icon: Icons.edit_rounded,
                        color: Utils.edit,
                        onTap: () async {
                          final result = await Get.to(() => EditSupplierPage(supplier: supplier));
                          if (result == true || result == null) {
                            supplierController.loadSuppliers();
                          }
                        },
                        tooltip: 'Editar',
                      ),
                      const SizedBox(height: 4),
                      _buildCompactActionButton(
                        icon: Icons.delete_rounded,
                        color: Utils.delete,
                        onTap: () => _deleteSupplier(supplier['_id'].toString()),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Información de contacto
          if (phone.isNotEmpty || email.isNotEmpty || address.isNotEmpty)
            Container(
              margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (phone.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: _buildContactRow(
                            icon: Icons.chat,
                            label: phone,
                            color: Color(0xFF25D366), // Color de WhatsApp
                            onTap: () => _openWhatsApp(phone),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _makePhoneCall(phone),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (email.isNotEmpty) ...[
                    if (phone.isNotEmpty) const SizedBox(height: 10),
                    _buildContactRow(
                      icon: Icons.mail_rounded,
                      label: email,
                      color: Color(0xFFDB4437), // Color de Gmail
                      onTap: () => _sendEmail(email),
                    ),
                  ],
                  if (address.isNotEmpty) ...[
                    if (phone.isNotEmpty || email.isNotEmpty) 
                      const SizedBox(height: 10),
                    _buildContactRow(
                      icon: Icons.location_on_rounded,
                      label: address,
                      color: Colors.orange,
                    ),
                  ],
                ],
              ),
            ),
        ],
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
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: color.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }
}
