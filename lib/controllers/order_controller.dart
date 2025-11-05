import 'package:get/get.dart';
import '../providers/order_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';
import 'customer_controller.dart';

class OrderController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();
  
  OrderProvider get _orderProvider => OrderProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _orders = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    // Cargar órdenes al inicializar
    loadOrdersForCurrentStore();
  }

  // ⭐ MÉTODO PARA REFRESCAR CUANDO CAMBIE LA TIENDA
  Future<void> refreshForStore() async {
    await loadOrdersForCurrentStore();
  }

  // ⭐ CARGAR ÓRDENES DE LA TIENDA ACTUAL
  Future<void> loadOrdersForCurrentStore() async {
    final currentStore = _storeController.currentStore;
    if (currentStore != null) {
      await loadOrders(storeId: currentStore['_id']);
    }
  }

  // Cargar órdenes
  Future<void> loadOrders({
    String? storeId,
    String? customerId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // ⭐ ASEGURAR QUE SIEMPRE SE USE EL STORE ID ACTUAL
      final effectiveStoreId = storeId ?? _storeController.currentStore?['_id'];
      
      // ✅ Validar que hay un storeId antes de cargar
      if (effectiveStoreId == null) {
        print('⚠️ OrderController: No hay tienda actual seleccionada');
        _orders.clear();
        return;
      }
      
      print('🔄 OrderController: Cargando órdenes para tienda: $effectiveStoreId');

      final result = await _orderProvider.getOrders(
        storeId: effectiveStoreId, // ⭐ Usar el storeId efectivo
        customerId: customerId,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        // ⭐ VALIDAR que todas las órdenes pertenecen a la tienda correcta
        for (final order in List<Map<String, dynamic>>.from(result['data'])) {
          final orderStoreId = order['storeId'];
          if (orderStoreId != effectiveStoreId) {
            print('🚨 OrderController: Orden con storeId incorrecto detectada!');
            print('   Expected: $effectiveStoreId, Got: $orderStoreId');
            print('   Order ID: ${order['_id']}');
          }
        }
        
        _orders.value = List<Map<String, dynamic>>.from(result['data']);
        print('✅ OrderController: ${_orders.length} órdenes cargadas para tienda $effectiveStoreId');
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando órdenes';
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

  // Obtener orden por ID
  Future<Map<String, dynamic>?> getOrderById(String id) async {
    _isLoading.value = true;

    try {
      final result = await _orderProvider.getOrderById(id);

      if (result['success']) {
        return result['data'];
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error obteniendo orden',
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

  // Crear orden
  Future<bool> createOrder({
    required String storeId,
    String? customerId,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? cashRegisterId,
    String? discountId,
  }) async {
    _isLoading.value = true;
    
    // ✅ LOG: Confirmación de creación de orden
    print('🆕 OrderController: Creando nueva orden');
    print('   StoreId: $storeId');
    print('   Items: ${items.length}');
    print('   Payment Method: $paymentMethod');

    try {
      final result = await _orderProvider.createOrder(
        storeId: storeId,
        customerId: customerId,
        items: items,
        paymentMethod: paymentMethod,
        cashRegisterId: cashRegisterId,
        discountId: discountId,
      );

      if (result['success']) {
        print('✅ OrderController: Orden creada exitosamente para tienda $storeId');
        
        // Refrescar lista de órdenes
        await loadOrders(storeId: storeId);
        
        // ⭐ Refrescar estadísticas de clientes si hay CustomerController instanciado
        try {
          final customerController = Get.find<CustomerController>();
          await customerController.loadCustomers();
          print('✅ OrderController: CustomerController refrescado después de crear orden');
        } catch (e) {
          print('ℹ️ OrderController: CustomerController no está instanciado');
        }
        
        Get.snackbar(
          'Éxito',
          'Orden creada correctamente',
          snackPosition: SnackPosition.TOP,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error creando orden',
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

  // Actualizar estado de orden
  Future<bool> updateOrderStatus({
    required String id,
    required String status,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _orderProvider.updateOrderStatus(
        id: id,
        status: status,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Estado actualizado correctamente',
          snackPosition: SnackPosition.TOP,
        );
        await loadOrders();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error actualizando estado',
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

  // Obtener reporte de ventas
  Future<Map<String, dynamic>?> getSalesReport({
    String? storeId,
    String? startDate,
    String? endDate,
    String? groupBy,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _orderProvider.getSalesReport(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
        groupBy: groupBy,
      );

      if (result['success']) {
        return result['data'];
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error obteniendo reporte',
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

  // Eliminar orden
  Future<bool> deleteOrder(String id) async {
    _isLoading.value = true;

    try {
      final result = await _orderProvider.deleteOrder(id);

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Orden eliminada correctamente',
          snackPosition: SnackPosition.TOP,
        );
        _orders.removeWhere((o) => o['_id'] == id);
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error eliminando orden',
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

  // Limpiar órdenes (útil para cambios de tienda)
  void clearOrders() {
    print('🧹 OrderController: Limpiando órdenes');
    _orders.clear();
  }
}
