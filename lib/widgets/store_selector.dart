import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_controller.dart';
import '../models/store.dart';
import '../utils/utils.dart';
import '../pages/store_management_page.dart';

class StoreSelector extends StatelessWidget {
  const StoreSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // Intentar obtener el controlador, si no existe retornar un ícono simple
    try {
      final storeController = Get.find<StoreController>();
      
      return Obx(() {
        if (storeController.isLoading.value) {
          return Container(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        if (storeController.availableStores.isEmpty) {
          return IconButton(
            icon: Icon(Icons.store, color: Colors.white70),
            onPressed: () {
              Get.snackbar(
                'Sin tiendas',
                'No hay tiendas disponibles',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          );
        }

        // Si el usuario NO es admin y solo tiene 1 tienda asignada, no mostrar selector
        if (!storeController.isAdmin.value && storeController.availableStores.length == 1) {
          return SizedBox.shrink(); // No mostrar nada
        }

        return PopupMenuButton<Store?>(
          tooltip: storeController.currentStore.value?.name ?? 'Seleccionar tienda',
          offset: Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.store,
              color: Colors.white,
              size: 20,
            ),
          ),
          itemBuilder: (context) => [
            if (storeController.isAdmin.value)
              PopupMenuItem<Store?>(
                value: null,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Utils.colorGnav.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.business,
                          color: Utils.colorGnav,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Todas las tiendas',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Utils.colorTexto,
                              ),
                            ),
                            Text(
                              'Vista completa del sistema',
                              style: TextStyle(
                                fontSize: 11,
                                color: Utils.colorTexto.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (storeController.isAdmin.value)
              PopupMenuItem<Store?>(
                enabled: false,
                child: Divider(height: 1),
              ),
            ...storeController.availableStores.map((store) {
              final isSelected = storeController.currentStore.value?.id == store.id;
              
              return PopupMenuItem<Store>(
                value: store,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Utils.colorBotones.withOpacity(0.05) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Utils.colorBotones.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.store,
                          color: Utils.colorBotones,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                                color: Utils.colorTexto,
                              ),
                            ),
                            if (store.address != null && store.address!.isNotEmpty)
                              Text(
                                store.address!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Utils.colorTexto.withOpacity(0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            if (storeController.isAdmin.value)
              PopupMenuItem<Store?>(
                enabled: false,
                child: Divider(height: 1),
              ),
            if (storeController.isAdmin.value)
              PopupMenuItem<Store?>(
                value: null,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Utils.colorBotones.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_business,
                          color: Utils.colorBotones,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Gestionar tiendas',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Utils.colorBotones,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  // Navegar a la página de gestión de tiendas
                  Future.delayed(Duration.zero, () {
                    Get.to(() => StoreManagementPage());
                  });
                },
              ),
          ],
          onSelected: (store) {
            if (store != null) {
              storeController.switchStore(store);
            }
          },
        );
      });
    } catch (e) {
      // Si el controlador no está disponible, mostrar un ícono deshabilitado
      return IconButton(
        icon: Icon(Icons.store_outlined, color: Colors.white54),
        onPressed: () {
          Get.snackbar(
            'No disponible',
            'El selector de tiendas no está disponible en este momento',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      );
    }
  }
}
