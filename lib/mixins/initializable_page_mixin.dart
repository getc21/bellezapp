import 'package:flutter/material.dart';

/// Mixin para inicializar datos en una página una sola vez
/// Previene race conditions y duplicate initialization
mixin InitializablePage<T extends StatefulWidget> on State<T> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        initializeOnce();
      }
    });
  }

  /// Override este método en la página para ejecutar código de inicialización
  /// Se ejecuta automáticamente una sola vez después del primer frame
  void initializeOnce() {}
}
