# 📱 Guía de Notificaciones QR - Android Fix

## Problema Original
Las notificaciones de descarga de QR no aparecían en Android, aunque el archivo se guardaba correctamente.

## Causa Raíz
1. **Permiso no solicitado**: Android 13+ requiere solicitar `POST_NOTIFICATIONS` en tiempo de ejecución
2. **Canal de notificación incompleto**: El canal no tenía importancia correcta establecida
3. **Inicialización incompleta**: No se inicializaba el plugin de notificaciones correctamente

## Soluciones Implementadas

### 1️⃣ Permiso de Notificación en Tiempo de Ejecución

**Archivo**: `lib/pages/product_list_page.dart`

Se agregó el método `_requestNotificationPermissions()`:

```dart
Future<void> _requestNotificationPermissions() async {
  if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? grantedNotificationPermission =
        await androidImplementation?.requestNotificationsPermission();
    
    log('[NOTIF] Permiso de notificación otorgado: $grantedNotificationPermission');
  }
}
```

**Se llama en `initState()`**:
```dart
@override
void initState() {
  super.initState();
  _initializeNotifications();
  _requestNotificationPermissions(); // 👈 AGREGADO
  // ...
}
```

### 2️⃣ Inicialización Mejorada de Notificaciones

El método `_initializeNotifications()` ahora:
- Crea el canal con `Importance.high` (criticidad)
- Habilita luces, vibración y sonido
- Registra todos los pasos con logs `[NOTIF]`

```dart
Future<void> _initializeNotifications() async {
  try {
    log('[NOTIF] Inicializando flutter_local_notifications...');
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'qr_downloads',
      'Descargas de QR',
      description: 'Notificaciones cuando se guarda un QR',
      importance: Importance.high, // ⭐ CRÍTICO para que se muestre
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    log('[NOTIF] ✅ Canal de notificación creado correctamente');
  } catch (e, stack) {
    log('[NOTIF] ❌ Error inicializando: $e\n$stack');
  }
}
```

### 3️⃣ Método de Mostrar Notificación

El método `_showQRNotification()` ahora:
- Especifica todos los parámetros de `AndroidNotificationDetails`
- Usa el mismo ID de canal que se creó
- Registra todo para debugging

```dart
Future<void> _showQRNotification(String fileName) async {
  try {
    log('[NOTIF] Intentando mostrar notificación para: $fileName');
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'qr_downloads', // Mismo ID del canal creado
      'Descargas de QR',
      channelDescription: 'Notificaciones cuando se guarda un QR',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      '📥 QR Descargado',
      'Archivo: $fileName',
      notificationDetails,
      payload: fileName,
    );
    log('[NOTIF] ✅ Notificación mostrada exitosamente');
  } catch (e, stack) {
    log('[NOTIF] ❌ Error mostrando notificación: $e');
    log('[NOTIF] Stack trace: $stack');
  }
}
```

## ✅ Verificaciones Completadas

- [x] **AndroidManifest.xml** contiene `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />`
- [x] **_requestNotificationPermissions()** se llama en `initState()`
- [x] **_initializeNotifications()** crea canal con `Importance.high`
- [x] **_showQRNotification()** usa el mismo ID de canal (`qr_downloads`)
- [x] **Logging detallado** con `[NOTIF]` para debugging

## 🧪 Pasos para Probar

### Requisitos Previos
1. Android 13+ (requerido para probar la solicitud de permiso)
2. App compilada en modo release o profile
3. Teléfono desbloqueado

### Procedimiento de Testing

#### Paso 1: Limpiar y Compilar
```bash
# En la carpeta bellezapp-frontend
flutter clean
flutter pub get
flutter run
```

#### Paso 2: Probar Permisos
1. Abre la app
2. Navega a **Product List** 
3. Verifica en los logs: Busca `[NOTIF] Permiso de notificación otorgado: true/false`
4. Si sale un dialog pidiendo permiso de notificaciones → **acepta**

#### Paso 3: Generar QR
1. Selecciona un producto
2. Toca el botón "📱 Generar QR"
3. En el dialog emergente, toca "💾 Guardar en Descargas"
4. Espera 2-3 segundos

#### Paso 4: Verificar Notificación
- **Opción A**: Mira en el notification center (desliza desde la parte superior)
- **Opción B**: Verifica los logs: Busca `[NOTIF] ✅ Notificación mostrada exitosamente`

### Debugging si No Funciona

#### Revisar Permisos
```dart
// En android/app/src/main/AndroidManifest.xml, debe existir:
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### Revisar Logs
```bash
# Terminal: muestra solo logs de notificaciones
flutter logs | grep "[NOTIF]"
```

#### Checklist de Debugging
- [ ] ¿El archivo QR se guarda correctamente? (SnackBar visible)
- [ ] ¿El log `[NOTIF] Intentando mostrar notificación` aparece?
- [ ] ¿El log `[NOTIF] ✅ Notificación mostrada exitosamente` aparece?
- [ ] ¿El permiso `POST_NOTIFICATIONS` está en AndroidManifest.xml?
- [ ] ¿Aceptaste el permiso cuando se pidió?
- [ ] ¿El teléfono tiene notificaciones habilitadas para la app?

## 📊 Flujo Completo de Notificaciones

```
initState()
    ↓
_initializeNotifications() 
    ↓ Crea canal 'qr_downloads' con Importance.high
_requestNotificationPermissions()
    ↓ Pide permiso POST_NOTIFICATIONS en Android 13+
[Usuario genera QR] → _saveQRToGallery()
    ↓
Guardar archivo PNG en Downloads
    ↓
_showQRNotification(fileName)
    ↓ Usa AndroidNotificationDetails con 'qr_downloads'
📱 Aparece notificación en notification center
```

## 🔧 Código Ubicado en

| Componente | Archivo | Líneas |
|------------|---------|--------|
| Inicialización | `lib/pages/product_list_page.dart` | 38-45 |
| Permisos | `lib/pages/product_list_page.dart` | 65-75 |
| Canal | `lib/pages/product_list_page.dart` | 560-590 |
| Mostrar | `lib/pages/product_list_page.dart` | 594-625 |

## 🎯 Próximos Pasos si Aún No Funciona

1. **Captura de pantalla de los logs** con `[NOTIF]`
2. **Verifica en Settings → Apps → Bellezapp → Notifications** que esté habilitado
3. **Reinicia el teléfono** (cache del plugin)
4. **Borra caché de la app**: Settings → Apps → Bellezapp → Storage → Clear Cache

---

## 📝 Notas Importantes

- ⚠️ En Android 12 y anteriores, las notificaciones deberían mostrar sin solicitar permiso
- ⚠️ `Importance.high` es crítico en Android 10+; sin esto la notificación se silencia
- ⚠️ El ID del canal (`qr_downloads`) debe ser el mismo en `createNotificationChannel()` y en `show()`
- ✅ El archivo se guarda **independientemente** de si la notificación funciona
