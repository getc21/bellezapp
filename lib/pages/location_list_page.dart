import 'dart:convert';

import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/controllers/location_controller.dart';
import 'package:bellezapp/pages/add_location_page.dart';
import 'package:bellezapp/pages/edit_location_page.dart';
import 'package:bellezapp/pages/location_products_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocationListPage extends StatefulWidget {
  const LocationListPage({super.key});

  @override
  State<LocationListPage> createState() => LocationListPageState();
}

class LocationListPageState extends State<LocationListPage> {
  final themeController = Get.find<ThemeController>();
  final locationController = Get.find<LocationController>();

  @override
  void initState() {
    super.initState();
    // Ya no necesitamos cargar ubicaciones aquí, el controller lo maneja
  }

  void _deleteLocation(int id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar esta ubicación?',
    );
    if (confirmed) {
      try {
        await locationController.deleteLocation(id);
      } catch (e) {
        Get.snackbar('Error', 'No se pudo eliminar la ubicación: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      body: Obx(() {
        if (locationController.isLoading) {
          return Center(child: Utils.loadingCustom());
        }
        
        return ListView.builder(
          itemCount: locationController.locations.length,
          itemBuilder: (context, index) {
            final location = locationController.locations[index];
            final fotoBase64 = location['foto'] ?? '';

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
                      ? Icon(Icons.location_on, color: Colors.grey.shade600)
                      : null,
                ),
                title: Utils.textTitle(location['name']),
                subtitle: Utils.textDescription(location['description'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
                        final result = await Get.to(EditLocationPage(location: location));
                        if (result == true) {
                          locationController.refreshLocations();
                        }
                      },
                      icon: const Icon(Icons.edit),
                      color: Utils.edit,
                    ),
                    IconButton(
                      onPressed: () {
                        _deleteLocation(location['id']);
                      },
                      icon: const Icon(Icons.delete),
                      color: Utils.delete,
                    ),
                  ],
                ),
                onTap: () {
                  Get.to(LocationProductsPage(
                    locationName: location['name'],
                    locationId: location['id'],
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
          final result = await Get.to(AddLocationPage());
          if (result == true) {
            locationController.refreshLocations();
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