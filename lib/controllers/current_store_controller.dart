import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/store.dart';
import '../models/user.dart';
import '../controllers/store_controller.dart';
import '../controllers/auth_controller.dart';
import '../utils/utils.dart';

class CurrentStoreController extends GetxController {
  final StoreController _storeController = Get.find<StoreController>();
  final AuthController _authController = Get.find<AuthController>();
  
  // Estado observable de la tienda actual
  final Rx<Store?> _currentStore = Rx<Store?>(null);
  final RxList<Store> _availableStores = <Store>[].obs;
  final RxBool _isLoading = false.obs;
  
  // Getters
  Store? get currentStore => _currentStore.value;
  Rx<Store?> get currentStoreObservable => _currentStore;
  List<Store> get availableStores => _availableStores;
  bool get isLoading => _isLoading.value;
  User? get currentUser => _authController.currentUser;
  
  // Getters de conveniencia
  bool get canSwitchStores => currentUser?.isAdmin ?? false;
  bool get hasStoreRestriction => currentUser?.hasStoreRestriction ?? false;
  String get currentStoreName => currentStore?.name ?? 'Sin tienda seleccionada';
  String get currentStoreCode => currentStore?.code ?? '';

  @override
  void onInit() {
    super.onInit();
    // No inicializar automáticamente - se hará después del login
  }

  // Inicializar después del login exitoso
  Future<void> initializeAfterLogin() async {
    await _initializeCurrentStore();
  }

  // Resetear estado al cerrar sesión
  void resetOnLogout() {
    _currentStore.value = null;
    _availableStores.clear();
    _isLoading.value = false;
  }

  // Inicializar la tienda actual basada en el usuario
  Future<void> _initializeCurrentStore() async {
    print('=== DEBUG: Inicializando CurrentStoreController ===');
    
    final user = currentUser;
    print('Usuario actual: ${user?.username} | Role: ${user?.role} | Store ID: ${user?.storeId}');
    
    if (user == null) {
      print('ERROR: Usuario es null, no se puede inicializar');
      return;
    }

    _isLoading.value = true;

    try {
      // Cargar tiendas disponibles
      await _loadAvailableStores();
      print('Tiendas cargadas: ${_availableStores.length}');
      
      for (var store in _availableStores) {
        print('  - Tienda: ${store.name} (ID: ${store.id}, Code: ${store.code})');
      }

      if (user.isAdmin) {
        print('Usuario es ADMIN - Seleccionando primera tienda disponible');
        // Admin puede ver todas las tiendas, seleccionar la primera por defecto
        if (_availableStores.isNotEmpty) {
          _currentStore.value = _availableStores.first;
          print('Tienda seleccionada para admin: ${_currentStore.value?.name}');
        } else {
          print('ERROR: No hay tiendas disponibles para admin');
        }
      } else if (user.storeId != null) {
        print('Usuario con tienda asignada - Buscando tienda ID: ${user.storeId}');
        // Empleado/manager con tienda asignada
        final userStore = _availableStores.firstWhereOrNull(
          (store) => store.id == user.storeId,
        );
        if (userStore != null) {
          _currentStore.value = userStore;
          print('Tienda encontrada y asignada: ${userStore.name}');
        } else {
          print('ERROR: Tienda asignada (ID: ${user.storeId}) no encontrada');
          // La tienda asignada no existe o está inactiva
          Get.snackbar(
            'Error',
            'Tu tienda asignada no está disponible. Contacta al administrador.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Utils.no.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        }
      } else {
        print('ERROR: Usuario sin tienda asignada');
        // Usuario sin tienda asignada
        Get.snackbar(
          'Atención',
          'No tienes una tienda asignada. Contacta al administrador.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
      
      print('Tienda final seleccionada: ${_currentStore.value?.name ?? 'NINGUNA'}');
      print('=== FIN DEBUG CurrentStoreController ===');
    } catch (e) {
      print('Error inicializando tienda actual: $e');
      Get.snackbar(
        'Error',
        'Error cargando información de tiendas',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Utils.no.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Cargar tiendas disponibles
  Future<void> _loadAvailableStores() async {
    final user = currentUser;
    if (user == null) return;

    if (user.isAdmin) {
      // Admin puede ver todas las tiendas activas
      _availableStores.value = _storeController.activeStores;
    } else if (user.storeId != null) {
      // Empleado/manager solo puede ver su tienda asignada
      final userStore = _storeController.stores.firstWhereOrNull(
        (store) => store.id == user.storeId && store.isActive,
      );
      _availableStores.value = userStore != null ? [userStore] : [];
    } else {
      _availableStores.value = [];
    }
  }

  // Cambiar tienda actual (solo para admin)
  Future<bool> switchToStore(Store store) async {
    if (!canSwitchStores) {
      Get.snackbar(
        'Acceso Denegado',
        'No tienes permisos para cambiar de tienda',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Utils.no.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }

    if (!store.isActive) {
      Get.snackbar(
        'Error',
        'La tienda seleccionada no está activa',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Utils.no.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }

    _currentStore.value = store;
    
    // Forzar actualización de widgets que usan GetBuilder
    update();
    
    print('DEBUG: Tienda cambiada a ${store.name} (ID: ${store.id})');
    
    return true;
  }

  // Mostrar selector de tienda (solo para admin)
  Future<void> showStoreSelector() async {
    if (!canSwitchStores) {
      Get.snackbar(
        'Acceso Denegado',
        'No tienes permisos para cambiar de tienda',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Utils.no.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Variable local para manejar la selección temporal
    Store? selectedStore = _currentStore.value;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Seleccionar Tienda',
              style: TextStyle(
                color: Utils.colorGnav,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selecciona la tienda para ver sus datos:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableStores.length,
                      itemBuilder: (context, index) {
                        final store = _availableStores[index];
                        final isSelected = store.id == selectedStore?.id;
                        
                        return Card(
                          color: isSelected ? Utils.colorGnav.withOpacity(0.1) : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? Utils.colorGnav : Colors.grey,
                              child: Text(
                                store.code,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              store.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Utils.colorGnav : null,
                              ),
                            ),
                            subtitle: Text(store.address),
                            trailing: isSelected 
                              ? Icon(Icons.check_circle, color: Utils.colorGnav)
                              : null,
                            onTap: () {
                              print('DEBUG: Seleccionando tienda ${store.name}');
                              setState(() {
                                selectedStore = store;
                              });
                              print('DEBUG: Tienda seleccionada temporalmente: ${selectedStore?.name}');
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: selectedStore != null ? () async {
                  try {
                    print('DEBUG: Aplicando cambio de tienda a ${selectedStore!.name}');
                    
                    // Cerrar el diálogo primero
                    Get.back();
                    
                    // Aplicar el cambio de tienda
                    _currentStore.value = selectedStore!;
                    update(); // Forzar actualización
                    
                    print('DEBUG: Tienda cambiada exitosamente a ${_currentStore.value?.name}');
                    
                    // Mostrar notificación después de cerrar el diálogo
                    await Future.delayed(Duration(milliseconds: 200));
                    
                    Get.snackbar(
                      'Tienda Cambiada',
                      'Ahora viendo datos de: ${selectedStore!.name}',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Utils.yes.withOpacity(0.8),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                    
                    // Opcional: Redirigir al homepage para refrescar todo
                    // Descomenta la siguiente línea si quieres volver al homepage
                    // Get.offAll(() => HomePage());
                    
                  } catch (e) {
                    print('ERROR aplicando cambio de tienda: $e');
                    Get.snackbar(
                      'Error',
                      'No se pudo cambiar la tienda: $e',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Utils.no.withOpacity(0.8),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                    );
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Utils.colorGnav,
                  foregroundColor: Colors.white,
                ),
                child: Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Recargar tiendas disponibles
  Future<void> refreshStores() async {
    await _storeController.loadStores();
    await _loadAvailableStores();
    
    // Verificar si la tienda actual sigue siendo válida
    if (currentStore != null) {
      final currentStoreStillValid = _availableStores.any(
        (store) => store.id == currentStore!.id,
      );
      
      if (!currentStoreStillValid) {
        // La tienda actual ya no está disponible, reinicializar
        await _initializeCurrentStore();
      }
    }
  }

  // Verificar si el usuario puede ver una tienda específica
  bool canAccessStore(int storeId) {
    final user = currentUser;
    if (user == null) return false;
    
    if (user.isAdmin) return true;
    
    return user.storeId == storeId;
  }

  // Obtener ID de tienda para filtros (null significa todas las tiendas para admin)
  int? getStoreFilterId() {
    final user = currentUser;
    if (user == null) return null;
    
    if (user.isAdmin) {
      // Admin puede elegir ver una tienda específica o todas
      return currentStore?.id;
    } else {
      // Empleados solo ven su tienda asignada
      return user.storeId;
    }
  }

  // Limpiar estado al cerrar sesión
  void clearStore() {
    _currentStore.value = null;
    _availableStores.clear();
  }
}