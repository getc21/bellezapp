import 'package:flutter/foundation.dart';
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
      final StoreController storeController = Get.find<StoreController>();
      
      // Escuchar cambios en la tienda actual
      _storeWorker = ever(storeController.currentStoreRx, (_) {
        if (mounted) {
          reloadData();
        }
      });
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }
  
  @override
  void dispose() {
    _storeWorker?.dispose();
    super.dispose();
  }
}
