# Sistema de Compresión de Imágenes 🖼️

## Descripción
Sistema automático de compresión de imágenes antes de subirlas a Cloudinary, para reducir espacio en almacenamiento sin afectar significativamente la calidad visual.

## Beneficios
✅ Reduce tamaño de imágenes 40-60%
✅ Mantiene buena calidad visual (85% de compresión)
✅ Mejora velocidad de subida a servidor
✅ Reduce costos de almacenamiento en CDN
✅ Mejora experiencia del usuario en conexiones lentas

## Implementación

### Dónde se usa
- **add_product_page.dart** - Agregar productos con imagen
- **add_category_page.dart** - Agregar categorías con logo
- **add_supplier_page.dart** - Agregar proveedores con imagen

### Cómo funciona

1. **Usuario selecciona imagen** desde cámara o galería
2. **`ImagePicker` limita dimensiones** a máximo 1024x1024
3. **`ImageCompressionService` comprime adicionalamente**:
   - Reduce a 1200x1200 máximo (mantiene aspecto)
   - Aplica compresión JPEG con calidad 85
   - Guarda archivo temporal comprimido
4. **App se queda con archivo comprimido** (no el original)

### Tamaño típico de reducción

```
Cámara (Huawei P30 lite): ~4 MB
      ↓ (ImagePicker 1024x1024, quality 85)
      2 MB
      ↓ (ImageCompressionService JPEG)
      ~1.2 MB (-70% del original)
```

## Métodos disponibles

### 1. Compresión estándar
```dart
final compressed = await ImageCompressionService.compressImage(
  imageFile: File(imagePath),
  quality: 85, // 0-100
);
```

### 2. Compresión optimizada para web
```dart
final compressed = await ImageCompressionService.compressImageForWeb(
  imageFile: imageFile,
  // quality: 75 (automático)
  // width: 800, height: 800 (automático)
);
```

### 3. Compresión alta calidad
```dart
final compressed = await ImageCompressionService.compressImageHighQuality(
  imageFile: imageFile,
  // quality: 90 (automático)
  // width: 1200, height: 1200 (automático)
);
```

### 4. Obtener información de imagen
```dart
final info = await ImageCompressionService.getImageInfo(imageFile);
print('Tamaño: ${info?.formattedSize}');
```

## Parámetros configurables

| Parámetro | Valor Actual | Rango | Impacto |
|-----------|-------------|-------|--------|
| quality | 85 | 0-100 | Mayor = más peso, mejor calidad |
| maxWidth | 1200 | 1-∞ | Mayor = más detalle |
| maxHeight | 1200 | 1-∞ | Mayor = más detalle |

### Recomendaciones de calidad

- **90+**: Calidad máxima, muy alto peso (archivos grandes)
- **85**: RECOMENDADO - Buen balance calidad/peso
- **75**: Web/mobile - aceptable calidad, poco peso
- **50-60**: Previsualizaciones pequeñas (thumbnails)
- **<50**: No recomendado

## Ventajas de esta implementación

✅ **No hay cambios en UI** - El usuario no ve diferencia
✅ **Fallback automático** - Si compresión falla, usa original
✅ **Debug logging** - Muestra tamaños en consola
✅ **Reutilizable** - Servicio centralizado
✅ **Async-safe** - No bloquea UI

## Logs de depuración

```
🖼️ [COMPRESS] Iniciando compresión de imagen...
   - Archivo original: /storage/emulated/0/DCIM/IMG_001.jpg
   - Tamaño original: 4.32 MB
✅ [COMPRESS] Imagen comprimida exitosamente
   - Tamaño comprimido: 1.24 MB
   - Reducción: 71.3%
   - Archivo: /data/user/0/com.example.bellezapp/cache/compressed_xxxxx.jpg
```

## Futuras mejoras

- [ ] Permitir usuario ajustar calidad manualmente
- [ ] Guardar versión original en galería del teléfono
- [ ] Caché de imágenes comprimidas
- [ ] WebP format para mejor compresión
- [ ] Manejo de imágenes PNG con transparencia

## Dependencias

```yaml
flutter_image_compress: ^2.4.0  # Motor de compresión
path_provider: ^2.1.5           # Directorios del sistema
```

## Troubleshooting

### Si la compresión falla
- La app automáticamente usa la imagen original
- Revisa el log: `❌ [COMPRESS] Error comprimiendo imagen:`
- Verifica que la imagen no esté corrupta

### Si el tamaño no reduce
- Imagen ya estaba comprimida (PNG, WebP)
- Aumentar compresión bajando `quality` a 75-80
- Reducir dimensiones (width/height)

---
**Última actualización**: Enero 2026
**Versión**: 1.0
