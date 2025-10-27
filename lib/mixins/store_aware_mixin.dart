import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_controller.dart';

/// Mixin para que las páginas se actualicen automáticamente cuando cambia la tienda
mixin StoreAwareMixin<T extends StatefulWidget> on State<T> {
  Worker? _storeWorker;
  
  /// Método que las clases deben implementar para recargar sus datos
  void reloadData();
  
  @override
  void initState() {
    super.initState();
    _setupStoreListener();
  }
  
  void _setupStoreListener() {
    try {
      final storeController = Get.find<StoreController>();
      
      // Escuchar cambios en la tienda actual
      _storeWorker = ever(storeController.currentStore, (_) {
        if (mounted) {
          print('🔄 ${T.toString()} detectó cambio de tienda, recargando datos...');
          reloadData();
        }
      });
    } catch (e) {
      print('⚠️ StoreController no disponible en ${T.toString()}: $e');
    }
  }
  
  @override
  void dispose() {
    _storeWorker?.dispose();
    super.dispose();
  }
}
