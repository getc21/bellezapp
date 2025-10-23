import 'package:bellezapp/controllers/theme_controller.dart';
import 'package:bellezapp/database/database_helper.dart';
import 'package:bellezapp/pages/add_location_page.dart';
import 'package:bellezapp/pages/edit_location_page.dart';
import 'package:bellezapp/pages/location_products_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocationListPage extends StatefulWidget {
  const LocationListPage({super.key});

  @override
  State<LocationListPage> createState() => LocationListPageState();
}

class LocationListPageState extends State<LocationListPage> {
  List<Map<String, dynamic>> _locations = [];
  final dbHelper = DatabaseHelper();
  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  void _loadLocations() async {
    final locations = await dbHelper.getLocations();
    setState(() {
      _locations = locations;
    });
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

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: Utils.colorFondo,
      body: ListView.builder(
        itemCount: _locations.length,
        itemBuilder: (context, index) {
          final location = _locations[index];
          return GestureDetector(
            onTap: () {
              Get.to(LocationProductsPage(
                locationId: location['id'],
                locationName: location['name'],
              ));
            },
            child: Card(
              color: Utils.colorFondoCards, // Color de fondo del Card
              margin: const EdgeInsets.symmetric(
                  vertical: 8.0, horizontal: 12.0), // Márgenes del Card
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0), // Bordes redondeados
              ),
              elevation: 4, // Sombra para el Card
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 12.0), // Espaciado interno del Card
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            location['name'] ?? 'Sin datos',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            location['description'] ?? 'Sin datos',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Utils.colorTexto,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Utils.edit, // Color de fondo
                            borderRadius: BorderRadius.only(
                                topRight:
                                    Radius.circular(16)), // Bordes redondeados
                          ), // Espaciado interno
                          child: IconButton(
                            onPressed: () {
                              Get.to(EditLocationPage(location: location));
                            },
                            icon: const Icon(Icons.edit),
                            color: Colors.white, // Color del ícono
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Utils.delete,
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(16)),
                          ),
                          child: IconButton(
                            onPressed: () {
                              _deleteLocation(location['id']);
                            },
                            icon: const Icon(Icons.delete),
                            color: Colors.white, // Color del ícono
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () async {
          Get.to(AddLocationPage());
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    )); // Cerrar Obx
  }
}
