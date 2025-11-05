import 'dart:io';

class ApiConfig {
  // IP de tu computadora en la red local
  static const String _localIP = '192.168.0.48';
  
  // IP para emulador Android
  static const String _emulatorIP = '10.0.2.2';
  
  // Puerto del backend
  static const String _port = '3000';
  
  // Detecta automáticamente si estamos en emulador o dispositivo físico
  static String get baseUrl {
    if (_isEmulator()) {
      print('🔧 ApiConfig: Usando emulador - $_emulatorIP:$_port');
      return 'http://$_emulatorIP:$_port/api';
    } else {
      print('📱 ApiConfig: Usando dispositivo físico - $_localIP:$_port');
      return 'http://$_localIP:$_port/api';
    }
  }
  
  // Detecta si estamos en un emulador
  static bool _isEmulator() {
    // En Android, podemos detectar el emulador por varias características
    if (Platform.isAndroid) {
      // Verificar variables de entorno específicas del emulador
      final androidHome = Platform.environment['ANDROID_HOME'];
      final isEmulator = Platform.environment['ANDROID_EMULATOR'];
      
      // Los emuladores tienen este directorio específico
      final isGenymotion = Platform.environment['USER']?.contains('genymotion') ?? false;
      
      return isEmulator == 'true' || 
             androidHome != null || 
             isGenymotion;
    }
    
    // Para iOS simulator (si lo usas en el futuro)
    if (Platform.isIOS) {
      return Platform.environment['SIMULATOR_DEVICE_NAME'] != null ||
             Platform.environment['SIMULATOR_ROOT'] != null;
    }
    
    // Por defecto, asumir dispositivo físico para mayor compatibilidad
    return false;
  }
  
  // Método para cambiar manualmente la configuración (útil para debugging)
  static String getUrlForMode({required bool useEmulator}) {
    if (useEmulator) {
      return 'http://$_emulatorIP:$_port/api';
    } else {
      return 'http://$_localIP:$_port/api';
    }
  }
  
  // Información de debug
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isEmulator': _isEmulator(),
      'platform': Platform.operatingSystem,
      'baseUrl': baseUrl,
      'localIP': _localIP,
      'emulatorIP': _emulatorIP,
      'environment': Platform.environment,
    };
  }
}