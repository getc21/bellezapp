import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/customer.dart';
import '../database/database_helper.dart';
import '../controllers/store_controller.dart';

class CustomerController extends GetxController {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Lista observable de customers
  final RxList<Customer> customers = <Customer>[].obs;
  final RxList<Customer> filteredCustomers = <Customer>[].obs;
  
  // Estados de carga
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  
  // Búsqueda
  final RxString searchQuery = ''.obs;
  
  // Customer seleccionado
  final Rx<Customer?> selectedCustomer = Rx<Customer?>(null);
  
  // Estadísticas
  final RxInt totalCustomers = 0.obs;
  final RxDouble totalRevenue = 0.0.obs;
  final RxInt activeCustomers = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
    
    // Escuchar cambios en la búsqueda
    ever(searchQuery, (_) => filterCustomers());
    
    // Escuchar cambios en la tienda actual
    try {
      final storeController = Get.find<StoreController>();
      ever(storeController.currentStore, (_) {
        print('🔄 Recargando clientes por cambio de tienda');
        loadCustomers();
      });
    } catch (e) {
      // StoreController no disponible
    }
  }

  // Cargar todos los customers
  Future<void> loadCustomers() async {
    try {
      isLoading.value = true;
      final customerList = await _databaseHelper.getCustomers();
      customers.value = customerList;
      filteredCustomers.value = customerList;
      
      // Actualizar estadísticas
      await updateStatistics();
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al cargar clientes: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Filtrar customers basado en la búsqueda
  void filterCustomers() {
    if (searchQuery.value.isEmpty) {
      filteredCustomers.value = customers;
    } else {
      filteredCustomers.value = customers.where((customer) {
        final query = searchQuery.value.toLowerCase();
        return customer.name.toLowerCase().contains(query) ||
               customer.phone.contains(query) ||
               (customer.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  // Buscar customers en base de datos
  Future<void> searchCustomers(String query) async {
    try {
      isSearching.value = true;
      searchQuery.value = query;
      
      if (query.isEmpty) {
        await loadCustomers();
      } else {
        final searchResults = await _databaseHelper.searchCustomers(query);
        filteredCustomers.value = searchResults;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error en la búsqueda: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSearching.value = false;
    }
  }

  // Agregar nuevo customer
  Future<bool> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      // Validar datos
      if (name.trim().isEmpty) {
        Get.snackbar('Error', 'El nombre es requerido');
        return false;
      }
      
      if (phone.trim().isEmpty) {
        Get.snackbar('Error', 'El teléfono es requerido');
        return false;
      }
      
      // Verificar si ya existe un customer con el mismo teléfono
      final exists = await _databaseHelper.customerExistsByPhone(phone.trim());
      if (exists) {
        Get.snackbar(
          'Cliente Duplicado', 
          'Ya existe un cliente registrado con el teléfono: ${phone.trim()}',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
      
      // Crear nuevo customer
      final customer = Customer(
        name: name.trim(),
        phone: phone.trim(),
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        address: address?.trim().isEmpty == true ? null : address?.trim(),
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      );
      
      // Insertar en base de datos
      final id = await _databaseHelper.insertCustomer(customer);
      
      // Agregar a la lista local
      final newCustomer = customer.copyWith(id: id);
      customers.add(newCustomer);
      filterCustomers();
      
      await updateStatistics();
      
      Get.snackbar(
        'Éxito',
        'Cliente agregado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al agregar cliente: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Actualizar customer existente
  Future<bool> updateCustomer({
    required int id,
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      // Validar datos
      if (name.trim().isEmpty) {
        Get.snackbar('Error', 'El nombre es requerido');
        return false;
      }
      
      if (phone.trim().isEmpty) {
        Get.snackbar('Error', 'El teléfono es requerido');
        return false;
      }
      
      // Verificar si ya existe otro customer con el mismo teléfono
      final exists = await _databaseHelper.customerExistsByPhone(
        phone.trim(), 
        excludeId: id,
      );
      if (exists) {
        Get.snackbar('Error', 'Ya existe otro cliente con este teléfono');
        return false;
      }
      
      // Buscar customer actual
      final currentCustomer = customers.firstWhereOrNull((c) => c.id == id);
      if (currentCustomer == null) {
        Get.snackbar('Error', 'Cliente no encontrado');
        return false;
      }
      
      // Crear customer actualizado
      final updatedCustomer = currentCustomer.copyWith(
        name: name.trim(),
        phone: phone.trim(),
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        address: address?.trim().isEmpty == true ? null : address?.trim(),
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      );
      
      // Actualizar en base de datos
      await _databaseHelper.updateCustomer(updatedCustomer);
      
      // Actualizar en lista local
      final index = customers.indexWhere((c) => c.id == id);
      if (index != -1) {
        customers[index] = updatedCustomer;
        filterCustomers();
      }
      
      Get.snackbar(
        'Éxito',
        'Cliente actualizado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al actualizar cliente: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Eliminar customer
  Future<bool> deleteCustomer(int id) async {
    try {
      await _databaseHelper.deleteCustomer(id);
      
      // Remover de lista local
      customers.removeWhere((c) => c.id == id);
      filterCustomers();
      
      await updateStatistics();
      
      Get.snackbar(
        'Éxito',
        'Cliente eliminado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al eliminar cliente: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Seleccionar customer
  void selectCustomer(Customer? customer) {
    selectedCustomer.value = customer;
  }

  // Actualizar estadísticas después de una compra
  Future<void> updateCustomerPurchaseStats(int customerId, double orderTotal) async {
    try {
      await _databaseHelper.updateCustomerPurchaseStats(customerId, orderTotal);
      
      // Actualizar customer en lista local
      final index = customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        final updatedCustomer = customers[index].copyWith(
          lastPurchase: DateTime.now(),
          totalSpent: customers[index].totalSpent + orderTotal,
          totalOrders: customers[index].totalOrders + 1,
        );
        customers[index] = updatedCustomer;
        filterCustomers();
      }
      
      await updateStatistics();
    } catch (e) {
      print('Error al actualizar estadísticas del cliente: $e');
    }
  }

  // Obtener top customers
  Future<List<Customer>> getTopCustomers({int limit = 10}) async {
    try {
      return await _databaseHelper.getTopCustomers(limit: limit);
    } catch (e) {
      print('Error al obtener top clientes: $e');
      return [];
    }
  }

  // Obtener customers recientes
  Future<List<Customer>> getRecentCustomers({int limit = 10}) async {
    try {
      return await _databaseHelper.getRecentCustomers(limit: limit);
    } catch (e) {
      print('Error al obtener clientes recientes: $e');
      return [];
    }
  }

  // Obtener customers activos
  Future<List<Customer>> getActiveCustomers({int daysAgo = 30}) async {
    try {
      return await _databaseHelper.getActiveCustomers(daysAgo: daysAgo);
    } catch (e) {
      print('Error al obtener clientes activos: $e');
      return [];
    }
  }

  // Actualizar estadísticas generales
  Future<void> updateStatistics() async {
    try {
      totalCustomers.value = customers.length;
      totalRevenue.value = customers.fold(0.0, (sum, customer) => sum + customer.totalSpent);
      
      final activeCustomersList = await getActiveCustomers();
      activeCustomers.value = activeCustomersList.length;
    } catch (e) {
      print('Error al actualizar estadísticas: $e');
    }
  }

  // Limpiar búsqueda
  void clearSearch() {
    searchQuery.value = '';
    filteredCustomers.value = customers;
  }

  // Ordenar customers por criterio
  void sortCustomers(String sortBy) {
    switch (sortBy) {
      case 'name':
        customers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'points':
        customers.sort((a, b) => b.loyaltyPoints.compareTo(a.loyaltyPoints));
        break;
      case 'spent':
        customers.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
        break;
      case 'orders':
        customers.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
        break;
    }
    // Actualizar lista filtrada
    if (searchQuery.value.isNotEmpty) {
      searchCustomers(searchQuery.value);
    } else {
      filteredCustomers.value = customers;
    }
  }

  // Obtener estadísticas de customers incluyendo puntos
  Map<String, dynamic> getCustomerStatistics() {
    if (customers.isEmpty) {
      return {
        'total_customers': 0,
        'active_customers': 0,
        'total_spent': 0.0,
        'average_spent': 0.0,
        'total_orders': 0,
        'total_loyalty_points': 0,
        'average_points_per_customer': 0.0,
      };
    }

    final activeCustomers = customers.where((c) => c.totalOrders > 0).length;
    final totalSpent = customers.fold(0.0, (sum, c) => sum + c.totalSpent);
    final totalOrders = customers.fold(0, (sum, c) => sum + c.totalOrders);
    final totalLoyaltyPoints = customers.fold(0, (sum, c) => sum + c.loyaltyPoints);

    return {
      'total_customers': customers.length,
      'active_customers': activeCustomers,
      'total_spent': totalSpent,
      'average_spent': totalSpent / customers.length,
      'total_orders': totalOrders,
      'total_loyalty_points': totalLoyaltyPoints,
      'average_points_per_customer': totalLoyaltyPoints / customers.length,
    };
  }

  // Obtener top customers por puntos
  Future<List<Customer>> getTopCustomersByPoints({int limit = 10}) async {
    return await _databaseHelper.getTopCustomersByPoints(limit: limit);
  }

  // Refrescar datos
  @override
  Future<void> refresh() async {
    await loadCustomers();
  }
}