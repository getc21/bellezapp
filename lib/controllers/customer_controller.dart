import 'package:get/get.dart';
import '../providers/customer_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class CustomerController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();
  
  CustomerProvider get _customerProvider => CustomerProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _customers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _filteredCustomers = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _searchQuery = ''.obs;

  // Getters
  List<Map<String, dynamic>> get customers => _customers;
  List<Map<String, dynamic>> get filteredCustomers => _filteredCustomers;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get searchQuery => _searchQuery.value;
  
  // Getters computados
  int get totalCustomers => _customers.length;
  int get activeCustomers => _customers.where((c) => c['isActive'] ?? true).length;
  double get totalRevenue => _customers.fold(0.0, (sum, c) => sum + ((c['totalSpent'] ?? 0.0).toDouble()));

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
    ever(_searchQuery, (_) => filterCustomers());
    // Recargar clientes cuando cambie la tienda seleccionada
    ever(_storeController.currentStoreRx, (_) => loadCustomers());
  }

  // Filtrar clientes
  void filterCustomers() {
    if (_searchQuery.value.isEmpty) {
      _filteredCustomers.value = _customers;
    } else {
      final query = _searchQuery.value.toLowerCase();
      _filteredCustomers.value = _customers.where((customer) {
        final name = customer['name']?.toString().toLowerCase() ?? '';
        final phone = customer['phone']?.toString().toLowerCase() ?? '';
        final email = customer['email']?.toString().toLowerCase() ?? '';
        return name.contains(query) || phone.contains(query) || email.contains(query);
      }).toList();
    }
  }

  // Actualizar búsqueda
  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  // Buscar clientes (alias para compatibilidad)
  void searchCustomers(String query) {
    updateSearchQuery(query);
  }

  // Limpiar búsqueda
  void clearSearch() {
    _searchQuery.value = '';
  }

  // Ordenar clientes
  void sortCustomers(String sortBy) {
    switch (sortBy) {
      case 'name':
        _customers.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        break;
      case 'recent':
        _customers.sort((a, b) {
          final dateA = a['createdAt'] != null ? DateTime.parse(a['createdAt']) : DateTime(2000);
          final dateB = b['createdAt'] != null ? DateTime.parse(b['createdAt']) : DateTime(2000);
          return dateB.compareTo(dateA);
        });
        break;
      case 'points':
        _customers.sort((a, b) {
          final pointsA = (a['loyaltyPoints'] ?? 0).toDouble();
          final pointsB = (b['loyaltyPoints'] ?? 0).toDouble();
          return pointsB.compareTo(pointsA);
        });
        break;
    }
    filterCustomers();
  }

  // Refrescar lista
  Future<void> refresh() async {
    await loadCustomers();
  }

  // ⭐ MÉTODO PARA REFRESCAR CUANDO CAMBIE LA TIENDA
  Future<void> refreshForStore() async {
    await loadCustomers();
  }

  // Cargar clientes
  Future<void> loadCustomers() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Obtener el storeId actual
      final currentStoreId = _storeController.currentStore?['_id'];
      if (currentStoreId == null) {
        _errorMessage.value = 'No hay tienda seleccionada';
        _customers.clear();
        filterCustomers();
        return;
      }

      final result = await _customerProvider.getCustomers(storeId: currentStoreId);

      print('🔍 CustomerController: Resultado del provider: $result');

      if (result['success'] == true) {
        final customersData = result['data'];
        print('🔍 CustomerController: Tipo de customersData: ${customersData.runtimeType}');
        
        try {
          if (customersData is List) {
            _customers.value = List<Map<String, dynamic>>.from(customersData);
            print('✅ CustomerController: ${_customers.length} clientes cargados correctamente');
          } else if (customersData is Map && customersData['customers'] is List) {
            // Manejar caso donde la data viene anidada
            _customers.value = List<Map<String, dynamic>>.from(customersData['customers']);
            print('✅ CustomerController: ${_customers.length} clientes cargados desde estructura anidada');
          } else {
            print('❌ CustomerController: customersData no es ni lista ni contiene customers');
            print('Estructura recibida: $customersData');
            _customers.clear();
            _errorMessage.value = 'Formato de datos inválido del servidor';
          }
        } catch (e) {
          print('❌ CustomerController: Error procesando datos: $e');
          _customers.clear();
          _errorMessage.value = 'Error procesando datos de clientes: $e';
        }
        
        filterCustomers();
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando clientes';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Obtener cliente por ID
  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    _isLoading.value = true;

    try {
      final result = await _customerProvider.getCustomerById(id);

      if (result['success']) {
        return result['data'];
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error obteniendo cliente',
          snackPosition: SnackPosition.TOP,
        );
        return null;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // Crear cliente
  Future<bool> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    _isLoading.value = true;

    try {
      // Obtener el storeId actual
      final currentStoreId = _storeController.currentStore?['_id'];
      if (currentStoreId == null) {
        Get.snackbar(
          'Error',
          'No hay tienda seleccionada',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      final result = await _customerProvider.createCustomer(
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
        storeId: currentStoreId,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Cliente creado correctamente',
          snackPosition: SnackPosition.TOP,
        );
        await loadCustomers();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error creando cliente',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Alias para compatibilidad con add_customer_page
  Future<bool> addCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    return createCustomer(
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );
  }

  // Actualizar cliente
  Future<bool> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _customerProvider.updateCustomer(
        id: id,
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Cliente actualizado correctamente',
          snackPosition: SnackPosition.TOP,
        );
        await loadCustomers();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error actualizando cliente',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Eliminar cliente
  Future<bool> deleteCustomer(String id) async {
    _isLoading.value = true;

    try {
      final result = await _customerProvider.deleteCustomer(id);

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Cliente eliminado correctamente',
          snackPosition: SnackPosition.TOP,
        );
        _customers.removeWhere((c) => c['_id'] == id);
        filterCustomers();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error eliminando cliente',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage.value = '';
  }
}
