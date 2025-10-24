import 'package:get/get.dart';
import '../models/discount.dart';
import '../database/database_helper.dart';

class DiscountController extends GetxController {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Lista observable de descuentos
  final RxList<Discount> discounts = <Discount>[].obs;
  final RxList<Discount> filteredDiscounts = <Discount>[].obs;
  final RxList<Discount> applicableDiscounts = <Discount>[].obs;
  
  // Estados de carga
  final RxBool isLoading = false.obs;
  
  // Búsqueda
  final RxString searchQuery = ''.obs;
  
  // Descuento seleccionado para aplicar a una orden
  final Rx<Discount?> selectedDiscount = Rx<Discount?>(null);
  final Rx<OrderDiscount?> appliedDiscount = Rx<OrderDiscount?>(null);

  @override
  void onInit() {
    super.onInit();
    loadDiscounts();
    
    // Escuchar cambios en la búsqueda
    ever(searchQuery, (_) => filterDiscounts());
  }

  // Cargar todos los descuentos
  Future<void> loadDiscounts() async {
    try {
      isLoading.value = true;
      final discountList = await _databaseHelper.getDiscounts();
      
      // Convertir Map<String, dynamic> a List<Discount>
      final discountObjects = discountList.map((map) => Discount.fromMap(map)).toList();
      
      discounts.value = discountObjects;
      filteredDiscounts.value = discountObjects;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al cargar descuentos: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Filtrar descuentos basado en la búsqueda
  void filterDiscounts() {
    if (searchQuery.value.isEmpty) {
      filteredDiscounts.value = discounts;
    } else {
      filteredDiscounts.value = discounts.where((discount) {
        final query = searchQuery.value.toLowerCase();
        return discount.name.toLowerCase().contains(query) ||
               discount.description.toLowerCase().contains(query);
      }).toList();
    }
  }

  // Buscar descuentos en base de datos
  Future<void> searchDiscounts(String query) async {
    try {
      searchQuery.value = query;
      
      if (query.isEmpty) {
        await loadDiscounts();
      } else {
        final searchResults = await _databaseHelper.searchDiscounts(query);
        final discountObjects = searchResults.map((map) => Discount.fromMap(map)).toList();
        filteredDiscounts.value = discountObjects;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error en la búsqueda: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Obtener descuentos aplicables para un monto específico
  void updateApplicableDiscounts(double totalAmount) {
    applicableDiscounts.value = discounts
        .where((discount) => discount.isApplicable(totalAmount))
        .toList();
  }

  // Agregar nuevo descuento
  Future<bool> addDiscount({
    required String name,
    required String description,
    required DiscountType type,
    required double value,
    double? minimumAmount,
    double? maximumDiscount,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
  }) async {
    try {
      // Validar datos
      if (name.trim().isEmpty) {
        Get.snackbar('Error', 'El nombre es requerido');
        return false;
      }
      
      if (value <= 0) {
        Get.snackbar('Error', 'El valor debe ser mayor a 0');
        return false;
      }
      
      if (type == DiscountType.percentage && value > 100) {
        Get.snackbar('Error', 'El porcentaje no puede ser mayor a 100%');
        return false;
      }
      
      if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
        Get.snackbar('Error', 'La fecha de inicio no puede ser posterior a la fecha de fin');
        return false;
      }
      
      // Crear nuevo descuento
      final discount = Discount(
        name: name.trim(),
        description: description.trim(),
        type: type,
        value: value,
        minimumAmount: minimumAmount,
        maximumDiscount: maximumDiscount,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
      );
      
      // Insertar en base de datos
      await _databaseHelper.insertDiscount(discount.toMap());
      
      // Recargar la lista para obtener el discount con ID
      await loadDiscounts();
      
      Get.snackbar(
        'Éxito',
        'Descuento agregado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al agregar descuento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Actualizar descuento existente
  Future<bool> updateDiscount({
    required int id,
    required String name,
    required String description,
    required DiscountType type,
    required double value,
    double? minimumAmount,
    double? maximumDiscount,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
  }) async {
    try {
      // Validar datos (mismas validaciones que en addDiscount)
      if (name.trim().isEmpty) {
        Get.snackbar('Error', 'El nombre es requerido');
        return false;
      }
      
      if (value <= 0) {
        Get.snackbar('Error', 'El valor debe ser mayor a 0');
        return false;
      }
      
      if (type == DiscountType.percentage && value > 100) {
        Get.snackbar('Error', 'El porcentaje no puede ser mayor a 100%');
        return false;
      }
      
      if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
        Get.snackbar('Error', 'La fecha de inicio no puede ser posterior a la fecha de fin');
        return false;
      }
      
      // Buscar descuento actual
      final currentDiscount = discounts.firstWhereOrNull((d) => d.id == id);
      if (currentDiscount == null) {
        Get.snackbar('Error', 'Descuento no encontrado');
        return false;
      }
      
      // Crear descuento actualizado
      final updatedDiscount = currentDiscount.copyWith(
        name: name.trim(),
        description: description.trim(),
        type: type,
        value: value,
        minimumAmount: minimumAmount,
        maximumDiscount: maximumDiscount,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
      );
      
      // Actualizar en base de datos
      await _databaseHelper.updateDiscount(updatedDiscount.toMap());
      
      // Actualizar en lista local
      final index = discounts.indexWhere((d) => d.id == id);
      if (index != -1) {
        discounts[index] = updatedDiscount;
        filterDiscounts();
      }
      
      Get.snackbar(
        'Éxito',
        'Descuento actualizado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al actualizar descuento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Eliminar descuento
  Future<bool> deleteDiscount(int id) async {
    try {
      await _databaseHelper.deleteDiscount(id);
      
      // Remover de lista local
      discounts.removeWhere((d) => d.id == id);
      filterDiscounts();
      
      Get.snackbar(
        'Éxito',
        'Descuento eliminado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al eliminar descuento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Aplicar descuento a un total
  void applyDiscount(Discount? discount, double totalAmount) {
    if (discount == null) {
      appliedDiscount.value = null;
      selectedDiscount.value = null;
      return;
    }

    if (!discount.isApplicable(totalAmount)) {
      Get.snackbar(
        'Error',
        'Este descuento no es aplicable al monto actual',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final discountAmount = discount.calculateDiscountAmount(totalAmount);
    final finalAmount = totalAmount - discountAmount;

    appliedDiscount.value = OrderDiscount(
      discount: discount,
      originalAmount: totalAmount,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
    );
    
    selectedDiscount.value = discount;
  }

  // Remover descuento aplicado
  void removeDiscount() {
    appliedDiscount.value = null;
    selectedDiscount.value = null;
  }

  // Activar/desactivar descuento
  Future<bool> toggleDiscountStatus(int id) async {
    try {
      final discount = discounts.firstWhereOrNull((d) => d.id == id);
      if (discount == null) return false;

      final updatedDiscount = discount.copyWith(isActive: !discount.isActive);
      await _databaseHelper.updateDiscount(updatedDiscount.toMap());

      final index = discounts.indexWhere((d) => d.id == id);
      if (index != -1) {
        discounts[index] = updatedDiscount;
        filterDiscounts();
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al cambiar estado del descuento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Obtener descuentos activos
  List<Discount> getActiveDiscounts() {
    return discounts.where((d) => d.isActive).toList();
  }

  // Limpiar búsqueda
  void clearSearch() {
    searchQuery.value = '';
    filteredDiscounts.value = discounts;
  }

  // Refrescar datos
  Future<void> refresh() async {
    await loadDiscounts();
  }
}