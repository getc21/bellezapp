# 🚀 Guía Rápida de Implementación - Bellezapp REST API

## 📋 Resumen

**Estado**: ✅ Migración completa - 19 páginas listas
**Pendiente**: Pruebas, renombrado, y limpieza de SQLite

---

## 🎯 Pasos para Completar la Migración

### 1️⃣ Iniciar Backend (si no está corriendo)

```powershell
cd ..\bellezapp-backend
npm run dev
```

Deberías ver:
```
✅ MongoDB connected successfully
🚀 Server running on port 3000
```

Si MongoDB no conecta:
```powershell
net start MongoDB
```

---

### 2️⃣ Probar las Páginas Nuevas

Ejecuta la app Flutter:
```powershell
flutter run
```

**Probar en este orden**:

✅ **Productos**
- [ ] Lista de productos
- [ ] Agregar producto
- [ ] Editar producto
- [ ] Eliminar producto

✅ **Categorías**
- [ ] Lista de categorías
- [ ] Agregar categoría
- [ ] Editar categoría
- [ ] Ver productos de una categoría

✅ **Proveedores**
- [ ] Lista de proveedores
- [ ] Agregar proveedor
- [ ] Editar proveedor
- [ ] Ver productos de un proveedor

✅ **Ubicaciones**
- [ ] Lista de ubicaciones
- [ ] Agregar ubicación
- [ ] Editar ubicación
- [ ] Ver productos en una ubicación

✅ **Órdenes**
- [ ] Lista de órdenes
- [ ] Ver detalles de orden (expandir)
- [ ] Historial de ventas con filtros

✅ **Reportes**
- [ ] Reporte general
- [ ] Reporte financiero

---

### 3️⃣ Renombrar Archivos (Eliminar sufijo _new)

**Opción A: Usar script automático**
```powershell
.\rename_new_pages.ps1
```

**Opción B: Manual**
En PowerShell:
```powershell
Get-ChildItem "lib/pages/*_new.dart" | ForEach-Object {
    $newName = $_.Name -replace '_new\.dart$', '.dart'
    
    # Backup del archivo antiguo
    if (Test-Path "lib/pages/$newName") {
        Move-Item "lib/pages/$newName" "lib/pages/$($newName -replace '\.dart$', '_old.dart')" -Force
    }
    
    # Renombrar nuevo
    Move-Item $_.FullName "lib/pages/$newName"
}
```

---

### 4️⃣ Verificar que No Hay Errores

```powershell
flutter pub get
flutter analyze
```

Si hay imports rotos, ejecutar:
```powershell
# Buscar imports que aún referencian *_new.dart
Get-ChildItem -Recurse "lib/*.dart" | Select-String "_new\.dart"
```

---

### 5️⃣ Limpiar Código SQLite

**Opción A: Usar script automático**
```powershell
.\cleanup_sqlite.ps1
```

**Opción B: Manual**

1. **Eliminar archivos**:
```powershell
Remove-Item "lib/database/database_helper.dart" -Force
Remove-Item "lib/services/auth_service.dart" -Force
Remove-Item "web/sqflite_sw.js" -Force
```

2. **Editar `pubspec.yaml`**:
Buscar y eliminar la línea:
```yaml
sqflite: ^2.4.2
```

3. **Ejecutar**:
```powershell
flutter clean
flutter pub get
```

4. **Verificar que no quedan referencias**:
```powershell
# Buscar DatabaseHelper
Get-ChildItem -Recurse "lib/*.dart" | Select-String "DatabaseHelper"

# Buscar sqflite
Get-ChildItem -Recurse "lib/*.dart" | Select-String "sqflite"
```

---

### 6️⃣ Prueba Final

```powershell
flutter run
```

**Verificar**:
- [ ] La app compila sin errores
- [ ] Todas las páginas cargan correctamente
- [ ] Las operaciones CRUD funcionan
- [ ] Los filtros funcionan (categoría, proveedor, ubicación)
- [ ] Los reportes muestran datos

---

## 🆘 Solución de Problemas

### Error: "No se puede conectar al backend"

**Síntoma**: "SocketException: Failed host lookup"

**Solución**:
1. Verificar que el backend está corriendo en `http://localhost:3000`
2. Si usas emulador Android, cambiar `localhost` por `10.0.2.2` en todos los providers
3. Si usas dispositivo físico, usar la IP de tu computadora

```dart
// En cada provider, cambiar:
static const String baseUrl = 'http://localhost:3000/api';
// Por:
static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
// O:
static const String baseUrl = 'http://192.168.X.X:3000/api'; // Tu IP local
```

### Error: "JWT token invalid"

**Síntoma**: Requests fallan con error 401

**Solución**:
1. Cerrar sesión
2. Volver a hacer login
3. Verificar que `AuthController` guarda el token correctamente

### Error: "DatabaseHelper no está definido"

**Síntoma**: Errores de compilación después de eliminar SQLite

**Solución**:
```powershell
# Buscar archivos que aún importan database_helper
Get-ChildItem -Recurse "lib/*.dart" | Select-String "database_helper"

# Eliminar esas líneas de import o actualizar el archivo
```

### Páginas antiguas (sin _new) aún se muestran

**Causa**: `home_page.dart` u otros archivos importan las páginas antiguas

**Solución**:
1. Abrir `lib/pages/home_page.dart`
2. Verificar que los imports no tienen sufijo `_old`
3. Si es necesario, actualizar los imports

---

## 📝 Checklist Final

Antes de considerar la migración completa:

- [ ] Backend corriendo sin errores
- [ ] MongoDB conectado
- [ ] 19 páginas renombradas (sin sufijo _new)
- [ ] Todas las pruebas pasadas
- [ ] SQLite eliminado completamente
- [ ] No hay errores de compilación
- [ ] No quedan referencias a `DatabaseHelper`
- [ ] No quedan referencias a `sqflite`
- [ ] App funciona en desarrollo
- [ ] Backup de archivos antiguos guardado

---

## 🎉 ¡Felicidades!

Si completaste todos los pasos, tu app ahora:
✅ Usa REST API en lugar de SQLite
✅ Se conecta a MongoDB
✅ Tiene arquitectura escalable
✅ Está lista para multi-usuario
✅ Puede desplegarse en producción

---

## 📚 Archivos de Referencia

- `MIGRATION_COMPLETE.md` - Documentación detallada de la migración
- `rename_new_pages.ps1` - Script para renombrar páginas
- `cleanup_sqlite.ps1` - Script para limpiar SQLite
- Backend: `bellezapp-backend/README.md`

---

## 🔜 Próximos Pasos Sugeridos

1. **Implementar gestión de storeId** desde el contexto del usuario autenticado
2. **Migrar `add_order_page.dart`** si se requiere la funcionalidad de crear órdenes
3. **Implementar reportes avanzados** con endpoints específicos:
   - Rotación de productos
   - Análisis financiero con entradas/salidas
   - Generación de PDFs
4. **Agregar paginación** para listas grandes
5. **Implementar caché** para mejorar performance
6. **Agregar tests** unitarios y de integración

---

**Última actualización**: $(date)
