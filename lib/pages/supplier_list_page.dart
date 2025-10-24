import 'dart:convert';

import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/controllers/supplier_controller.dart';
import 'package:bellezapp/pages/add_supplier_page.dart';
import 'package:bellezapp/pages/edit_supplier_page.dart';
import 'package:bellezapp/pages/supplier_products_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => SupplierListPageState();
}

class SupplierListPageState extends State<SupplierListPage> {
  final themeController = Get.find<ThemeController>();
  final supplierController = Get.find<SupplierController>();

  @override
  void initState() {
    super.initState();
    // Ya no necesitamos cargar proveedores aquí, el controller lo maneja
  }

  void _deleteSupplier(int id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar este proveedor?',
    );
    if (confirmed) {
      try {
        await supplierController.deleteSupplier(id);
      } catch (e) {
        Get.snackbar('Error', 'No se pudo eliminar el proveedor: $e');
      }
    }
  }

  void _callPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      Get.snackbar('Error', 'No se pudo abrir la aplicación de teléfono');
    }
  }

  void _sendWhatsApp(String phone) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'No se pudo abrir WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      body: Obx(() {
        if (supplierController.isLoading) {
          return Center(child: Utils.loadingCustom());
        }
        
        return ListView.builder(
          itemCount: supplierController.suppliers.length,
          itemBuilder: (context, index) {
            final supplier = supplierController.suppliers[index];
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
                      ? Icon(Icons.business, color: Colors.grey.shade600)
                      : null,
                ),
                title: Utils.textTitle(supplier['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Utils.textDescription(supplier['description'] ?? ''),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          supplier['phone'] ?? 'Sin teléfono',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          supplier['email'] ?? 'Sin email',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (supplier['phone'] != null && supplier['phone'].isNotEmpty) ...[
                      IconButton(
                        onPressed: () => _callPhone(supplier['phone']),
                        icon: const Icon(Icons.phone),
                        color: Colors.green,
                        tooltip: 'Llamar',
                      ),
                      IconButton(
                        onPressed: () => _sendWhatsApp(supplier['phone']),
                        icon: const Icon(Icons.message),
                        color: Colors.blue,
                        tooltip: 'WhatsApp',
                      ),
                    ],
                    IconButton(
                      onPressed: () async {
                        final result = await Get.to(EditSupplierPage(supplier: supplier));
                        if (result == true) {
                          supplierController.refreshSuppliers();
                        }
                      },
                      icon: const Icon(Icons.edit),
                      color: Utils.edit,
                    ),
                    IconButton(
                      onPressed: () {
                        _deleteSupplier(supplier['id']);
                      },
                      icon: const Icon(Icons.delete),
                      color: Utils.delete,
                    ),
                  ],
                ),
                onTap: () {
                  Get.to(SupplierProductsPage(
                    supplierName: supplier['name'],
                    supplierId: supplier['id'],
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
          final result = await Get.to(AddSupplierPage());
          if (result == true) {
            supplierController.refreshSuppliers();
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