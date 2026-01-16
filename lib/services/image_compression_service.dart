import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio para comprimir imágenes antes de subirlas al servidor
class ImageCompressionService {
  /// Calidad de compresión (0-100)
  /// 85 = buena calidad con reducción de ~40-50% del tamaño
  /// 75 = calidad media con reducción de ~50-60% del tamaño
  static const int defaultQuality = 85;

  /// Ancho máximo de la imagen (mantiene aspecto)
  static const int maxWidth = 1200;

  /// Alto máximo de la imagen (mantiene aspecto)
  static const int maxHeight = 1200;

  /// Comprime una imagen desde un archivo
  /// Retorna el archivo comprimido
  /// [imageFile] - archivo de imagen original
  /// [quality] - calidad de compresión (0-100, default 85)
  /// [maxWidth] - ancho máximo (default 1200)
  /// [maxHeight] - alto máximo (default 1200)
  static Future<File?> compressImage({
    required File imageFile,
    int quality = defaultQuality,
    int width = maxWidth,
    int height = maxHeight,
  }) async {
    try {
      if (kDebugMode) {
        print('🖼️ [COMPRESS] Iniciando compresión de imagen...');
        print('   - Archivo original: ${imageFile.path}');
        print('   - Tamaño original: ${_formatBytes(imageFile.lengthSync())}');
      }

      // Obtener directorio temporal
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Comprimir imagen usando flutter_image_compress
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: width,
        minHeight: height,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        if (await compressedFile.exists() && compressedFile.lengthSync() > 0) {
          final originalSize = imageFile.lengthSync();
          final compressedSize = compressedFile.lengthSync();
          final reduction =
              ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);

          if (kDebugMode) {
            print('✅ [COMPRESS] Imagen comprimida exitosamente');
            print('   - Tamaño comprimido: ${_formatBytes(compressedSize)}');
            print('   - Reducción: $reduction%');
            print('   - Archivo: ${result.path}');
          }

          return compressedFile;
        } else {
          if (kDebugMode) {
            print('⚠️ [COMPRESS] Compresión falló o resultado vacío, usando original');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('⚠️ [COMPRESS] Compresión retornó null');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [COMPRESS] Error comprimiendo imagen: $e');
      }
      return null;
    }
  }

  /// Comprime una imagen con parámetros optimizados para web
  /// (calidad más baja para ahorrar ancho de banda)
  static Future<File?> compressImageForWeb({
    required File imageFile,
  }) async {
    return compressImage(
      imageFile: imageFile,
      quality: 75, // Calidad ligeramente menor para web
      width: 800,
      height: 800,
    );
  }

  /// Comprime una imagen con máxima calidad (para galería)
  static Future<File?> compressImageHighQuality({
    required File imageFile,
  }) async {
    return compressImage(
      imageFile: imageFile,
      quality: 90, // Calidad alta
      width: maxWidth,
      height: maxHeight,
    );
  }

  /// Formatea bytes a formato legible (KB, MB, etc)
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Obtiene información sobre una imagen
  static Future<ImageInfo?> getImageInfo(File imageFile) async {
    try {
      final size = imageFile.lengthSync();
      final lastModified = imageFile.lastModifiedSync();

      return ImageInfo(
        filePath: imageFile.path,
        fileSizeBytes: size,
        lastModified: lastModified,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [COMPRESS] Error obteniendo info de imagen: $e');
      }
      return null;
    }
  }
}

/// Información de una imagen
class ImageInfo {
  final String filePath;
  final int fileSizeBytes;
  final DateTime lastModified;

  ImageInfo({
    required this.filePath,
    required this.fileSizeBytes,
    required this.lastModified,
  });

  String get formattedSize => _formatSize(fileSizeBytes);

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  String toString() => 'ImageInfo($filePath, $formattedSize)';
}

