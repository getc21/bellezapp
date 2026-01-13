/// Mapeo de nombres de iconos a emojis o Material Icons
class IconMapper {
  static final Map<String, String> _iconMap = {
    // Transporte
    'icon-transporte': '🚚',
    'transporte': '🚚',
    'transport': '🚚',
    
    // Salarios
    'icon-salarios': '💰',
    'salarios': '💰',
    'salaries': '💰',
    'wages': '💰',
    
    // Mantenimiento
    'icon-mantenimiento': '🔧',
    'mantenimiento': '🔧',
    'maintenance': '🔧',
    
    // Servicios
    'icon-servicios': '🛠️',
    'servicios': '🛠️',
    'services': '🛠️',
    
    // Alimentación
    'icon-alimentacion': '🍔',
    'alimentacion': '🍔',
    'food': '🍔',
    'comida': '🍔',
    
    // Utilidades
    'icon-utilidades': '💡',
    'utilidades': '💡',
    'utilities': '💡',
    
    // Oficina
    'icon-oficina': '🏢',
    'oficina': '🏢',
    'office': '🏢',
    
    // Marketing
    'icon-marketing': '📢',
    'marketing': '📢',
    'promocion': '📢',
    
    // Impuestos
    'icon-impuestos': '📋',
    'impuestos': '📋',
    'taxes': '📋',
    
    // Otros
    'icon-otros': '📌',
    'otros': '📌',
    'other': '📌',
    'miscellaneous': '📌',
    
    // Gastos generales
    'icon-gastos': '💸',
    'gastos': '💸',
    'expenses': '💸',
    
    // Equipos
    'icon-equipos': '⚙️',
    'equipos': '⚙️',
    'equipment': '⚙️',
    
    // Suministros
    'icon-suministros': '📦',
    'suministros': '📦',
    'supplies': '📦',
    
    // Viajes
    'icon-viajes': '✈️',
    'viajes': '✈️',
    'travel': '✈️',
    
    // Capacitación
    'icon-capacitacion': '📚',
    'capacitacion': '📚',
    'training': '📚',
    
    // Seguros
    'icon-seguros': '🛡️',
    'seguros': '🛡️',
    'insurance': '🛡️',
  };

  /// Obtiene el emoji correspondiente al nombre del icono
  /// Si no encuentra coincidencia, devuelve un emoji por defecto
  static String getIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return '💼'; // Emoji por defecto
    }

    // Buscar coincidencia exacta (case-insensitive)
    final lowerName = iconName.toLowerCase();
    if (_iconMap.containsKey(lowerName)) {
      return _iconMap[lowerName]!;
    }

    // Buscar si contiene alguna palabra clave
    for (var key in _iconMap.keys) {
      if (lowerName.contains(key)) {
        return _iconMap[key]!;
      }
    }

    // Si no encuentra coincidencia, devolver emoji por defecto
    return '💼';
  }

  /// Agrega un nuevo icono al mapeo
  static void addIcon(String name, String icon) {
    _iconMap[name.toLowerCase()] = icon;
  }
}
