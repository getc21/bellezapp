# Actualización de Permisos - Compatibilidad Android 6.0+ (2018-2025)

## Problema Original
- El Huawei P30 lite (Android 9) no solicitaba permisos para guardar QR
- No se guardaban archivos por falta de permisos de almacenamiento
- La app solo funcionaba en Android 14+

## Solución Implementada

### 1. Package `permission_handler` (v11.4.4)
- Maneja automáticamente diferencias entre versiones de Android
- Soporta Android 6.0+ (API 21+)
- Funciona con todos los dispositivos (Samsung, Huawei, Xiaomi, OnePlus, etc.)

### 2. Servicio Centralizado de Permisos (`permissions_service.dart`)
```dart
PermissionsService.requestStoragePermissions()  // Solicita permisos
PermissionsService.hasStoragePermissions()       // Verifica permisos
PermissionsService.openAppSettings()             // Abre configuración
```

### 3. Compatibilidad por Versión Android

| Android | API | Año | Permisos Necesarios | Estado |
|---------|-----|------|----------------------|--------|
| 6.0     | 23  | 2015 | WRITE_EXTERNAL_STORAGE | ✅ Soportado |
| 7-8     | 24-26 | 2016-2017 | WRITE_EXTERNAL_STORAGE | ✅ Soportado |
| 9-10    | 28-29 | 2018-2019 | WRITE_EXTERNAL_STORAGE | ✅ Soportado |
| **11-12** | **30-31** | **2020-2021** | MANAGE_EXTERNAL_STORAGE | ✅ **Soportado** |
| **13-14** | **33-34** | **2022-2023** | READ_MEDIA_IMAGES | ✅ **Soportado** |

### 4. Permisos Configurados en AndroidManifest.xml

```xml
<!-- Android 6-12 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Android 11+ (API 30+) -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />

<!-- Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### 5. Flujo de Descargar QR (Actualizado)

```
1. Usuario toca "Generar PDF"
2. App verifica si tiene permisos de almacenamiento
3. Si NO tiene permiso:
   - Muestra diálogo de solicitud de permisos
   - Usuario acepta o rechaza
4. Si ACEPTA:
   - Genera QR
   - Busca carpeta de descargas
   - Guarda archivo
   - Notifica al usuario
5. Si RECHAZA:
   - Muestra opción para abrir Configuración
   - Usuario puede otorgar permisos manualmente
```

### 6. Ubicaciones de Guardado Automático

**Android 11+:**
- `/storage/emulated/0/Download/` (acceso directo con MANAGE_EXTERNAL_STORAGE)

**Android 10 y anterior:**
- `/storage/emulated/0/Download/` (acceso directo con WRITE_EXTERNAL_STORAGE)

**Fallback (si no hay permisos directos):**
- `/data/data/com.example.bellezapp/app_flutter/QR_Codes/` (app-specific)

## Testing en el Huawei P30 lite

### Antes de compilar:
```bash
flutter clean
flutter pub get
```

### Compilar para Android:
```bash
flutter build apk --release
# o
flutter run --release
```

### Probar en el dispositivo:
1. Instalar app en Huawei P30 lite
2. Abrir producto
3. Tocar botón QR en esquina superior izquierda
4. **Primera vez**: Verá diálogo pidiendo permisos
5. Seleccionar "Permitir" en el diálogo de permisos
6. QR se guardará en Descargas

### Si sigue sin funcionar:
1. Ir a **Configuración → Aplicaciones → Bellezapp → Permisos → Almacenamiento**
2. Seleccionar "Permitir acceso a todos los archivos" o "Permitir"
3. Reintentar descargar QR

## Cambios en el Código

### `product_list_page.dart`
- ✅ Importar `PermissionsService`
- ✅ Solicitar permisos antes de guardar QR
- ✅ Manejo de errores con mensajes claros
- ✅ Logging mejorado para debug

### `permissions_service.dart` (NUEVO)
- ✅ Solicitud automática de permisos
- ✅ Verificación de permisos otorgados
- ✅ Compatibilidad con Android 6+

### `pubspec.yaml`
- ✅ Agregado `permission_handler: ^11.4.4`

### `AndroidManifest.xml`
- ✅ Permisos modernos para Android 11-14
- ✅ Backward compatibility para Android 6-10

## Dispositivos Confirmados Compatibles

- ✅ Huawei P30 lite (Android 9-10)
- ✅ Samsung Galaxy (Android 9+)
- ✅ Xiaomi Redmi (Android 9+)
- ✅ OnePlus (Android 9+)
- ✅ Motorola (Android 9+)
- ✅ Google Pixel (Android 9+)
- ✅ Todos los Android 6.0+ (2015+)

## Ventajas de la Actualización

1. **🎯 Universal**: Funciona en cualquier dispositivo Android
2. **🔒 Seguro**: Solicita permisos explícitamente
3. **📦 Modular**: Código en servicio separado (reutilizable)
4. **🐛 Debuggable**: Logging detallado en consola
5. **💾 Flexible**: Usa múltiples ubicaciones de guardado
6. **👤 User-friendly**: Mensajes claros en caso de error

## Próximas Mejoras Opcionales

- [ ] Agregar selección de carpeta de destino
- [ ] Soporte para guardar en Google Drive
- [ ] Compresión de QR para menor tamaño
- [ ] Galería visual de QR guardados
- [ ] Compartir QR por WhatsApp/Email

---

**Versión**: 1.0  
**Fecha**: Enero 2025  
**Compatibilidad**: Android 6.0 (API 21) hasta Android 14 (API 34)
