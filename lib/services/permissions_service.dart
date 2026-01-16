import 'package:permission_handler/permission_handler.dart' as ph;
import 'dart:io';
import 'package:flutter/foundation.dart';

class PermissionsService {
  /// Solicitar permisos de almacenamiento (compatible con Android 6+)
  static Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      // Android 11+ (API 30+): No necesita WRITE_EXTERNAL_STORAGE
      // Android 9-10: Necesita WRITE_EXTERNAL_STORAGE
      // Android 6-8: Necesita ambos
      
      ph.PermissionStatus status;
      
      if (kDebugMode) {
        print('🔵 [PERMISOS] Solicitando permisos de almacenamiento...');
      }

      // Para Android 13+ (API 33+): usar READ_MEDIA_IMAGES
      if (await ph.Permission.manageExternalStorage.isDenied) {
        status = await ph.Permission.manageExternalStorage.request();
        if (kDebugMode) {
          print('🟡 [PERMISOS] manageExternalStorage: $status');
        }
      }

      // Solicitar WRITE_EXTERNAL_STORAGE para Android < 13
      if (await ph.Permission.storage.isDenied) {
        status = await ph.Permission.storage.request();
        if (kDebugMode) {
          print('🟡 [PERMISOS] storage (WRITE): $status');
        }
      }

      // Solicitar READ_EXTERNAL_STORAGE
      if (await ph.Permission.photos.isDenied) {
        status = await ph.Permission.photos.request();
        if (kDebugMode) {
          print('🟡 [PERMISOS] photos (READ): $status');
        }
      }

      // Verificar si los permisos fueron otorgados
      final storageGranted = await ph.Permission.storage.isGranted;
      final manageGranted = await ph.Permission.manageExternalStorage.isGranted;
      final photosGranted = await ph.Permission.photos.isGranted;

      final hasPermission = storageGranted || manageGranted || photosGranted;

      if (kDebugMode) {
        print('✅ [PERMISOS] Permisos otorgados:');
        print('   - Storage: $storageGranted');
        print('   - Manage: $manageGranted');
        print('   - Photos: $photosGranted');
        print('   - Resultado final: $hasPermission');
      }

      return hasPermission;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PERMISOS] Error solicitando permisos: $e');
      }
      return false;
    }
  }

  /// Verificar si los permisos ya fueron otorgados
  static Future<bool> hasStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final storageGranted = await ph.Permission.storage.isGranted;
      final manageGranted = await ph.Permission.manageExternalStorage.isGranted;
      final photosGranted = await ph.Permission.photos.isGranted;

      return storageGranted || manageGranted || photosGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PERMISOS] Error verificando permisos: $e');
      }
      return false;
    }
  }

  /// Abrir configuración de la app si los permisos fueron denegados
  static Future<void> openAppSettings() async {
    if (kDebugMode) {
      print('🔵 [PERMISOS] Abriendo configuración de la app...');
    }
    await ph.openAppSettings();
  }
}
