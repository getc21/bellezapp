import 'package:flutter/material.dart';

/// Utilidades centralizadas para manejo de temas
/// Proporciona métodos para obtener colores y estados de tema de forma consistente
class ThemeUtils {
  /// Determina si el modo oscuro está activo
  static bool isDarkMode(ThemeMode themeMode, Brightness systemBrightness) {
    return themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && systemBrightness == Brightness.dark);
  }

  /// Obtiene el color para texto secundario basado en el modo oscuro
  static Color getSecondaryTextColor(bool isDark) {
    return isDark ? Colors.grey[400]! : Colors.grey[600]!;
  }

  /// Obtiene el color de fondo basado en el modo oscuro
  static Color getBackgroundColor(bool isDark) {
    return isDark ? Colors.grey[900]! : Colors.grey[50]!;
  }

  /// Obtiene el color de superficie (cards, containers) basado en el modo oscuro
  static Color getSurfaceColor(bool isDark) {
    return isDark ? Colors.grey[800]! : Colors.white;
  }

  /// Obtiene el color de texto principal basado en el modo oscuro
  static Color getPrimaryTextColor(bool isDark) {
    return isDark ? Colors.white : Colors.black87;
  }

  /// Obtiene el color de borde basado en el modo oscuro
  static Color getBorderColor(bool isDark) {
    return isDark ? Colors.grey[700]! : Colors.grey[300]!;
  }

  /// Obtiene el color de sombra basado en el modo oscuro
  static Color getShadowColor(bool isDark) {
    return isDark ? Colors.black54 : Colors.black26;
  }
}
