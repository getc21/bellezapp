import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../providers/category_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class CategoryController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();
  
  CategoryProvider get _categoryProvider => CategoryProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _categories = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  // ⭐ MÉTODO PARA REFRESCAR CUANDO CAMBIE LA TIENDA
  Future<void> refreshForStore() async {
    await loadCategories();
  }

  // Cargar categorías
  Future<void> loadCategories() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _categoryProvider.getCategories();

      if (result['success']) {
        _categories.value = List<Map<String, dynamic>>.from(result['data']);
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando categorías';
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

  // Obtener categoría por ID
  Future<Map<String, dynamic>?> getCategoryById(String id) async {
    _isLoading.value = true;

    try {
      final result = await _categoryProvider.getCategoryById(id);

      if (result['success']) {
        return result['data'];
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error obteniendo categoría',
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

  // Crear categoría
  Future<bool> createCategory({
    required String name,
    String? description,
    File? imageFile,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _categoryProvider.createCategory(
        name: name,
        description: description,
        imageFile: imageFile,
      );

      if (result['success']) {
        // No mostrar snackbar aquí, se manejará en la página
        await loadCategories();
        print('🎯 CategoryController: Retornando true');
        return true;
      } else {
        final errorMessage = result['message'] ?? 'Error creando categoría';
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red[800],
          duration: Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
        duration: Duration(seconds: 3),
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Actualizar categoría
  Future<bool> updateCategory({
    required String id,
    String? name,
    String? description,
    File? imageFile,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _categoryProvider.updateCategory(
        id: id,
        name: name,
        description: description,
        imageFile: imageFile,
      );

      if (result['success']) {
        // No mostrar snackbar aquí, se manejará en la página
        await loadCategories();
        return true;
      } else {
        // No mostrar snackbar aquí, se manejará en la página si es necesario
        return false;
      }
    } catch (e) {
      // No mostrar snackbar aquí, se manejará en la página si es necesario
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Eliminar categoría
  Future<bool> deleteCategory(String id) async {
    _isLoading.value = true;

    try {
      final result = await _categoryProvider.deleteCategory(id);

      if (result['success']) {
        // No mostrar snackbar aquí, se manejará en la página
        _categories.removeWhere((c) => c['_id'] == id);
        return true;
      } else {
        // No mostrar snackbar aquí, se manejará en la página si es necesario
        return false;
      }
    } catch (e) {
      // No mostrar snackbar aquí, se manejará en la página si es necesario
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
