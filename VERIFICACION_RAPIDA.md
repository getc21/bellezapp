# ⚡ VERIFICACIÓN RÁPIDA - 5 Minutos

## 🎯 Objetivo
Verificar que todos los 6 problemas han sido resueltos

---

## TEST 1: Precio en QR (1 min)
**Ubicación**: `add_order_page.dart` → Escanear QR

**Pasos**:
1. Abre app
2. Ve a `Add Order`
3. Escanea código QR de cualquier producto
4. ✅ Si ves precio > 0 → RESUELTO
5. ❌ Si ves 0.00 → CHECK logs con `grep -i "salePrice"`

**Validación**:
```bash
# Backend debe retornar salePrice
curl "http://192.168.0.48:3000/api/products/search?storeId=TUSTORE&productId=TUPROD"
# Busca "salePrice": en la respuesta
```

---

## TEST 2: Stock Auto-Update (2 min)
**Ubicación**: `product_list_page.dart` → `add_order_page.dart` (redondo)

**Pasos**:
1. Ve a `Product List`, nota el stock de un producto (ej: 50)
2. Ve a `Add Order`
3. Crea una venta de ese producto
4. Vuelve a `Product List`
5. ✅ Si stock bajó (ej: 49) → RESUELTO
6. ❌ Si sigue en 50 → El `loadProductsForCurrentStore()` no se ejecutó

**Logs esperados**:
```
[INFO] ProductController: Loading products for store...
[INFO] ProductController: Products loaded: X items
```

---

## TEST 3: StoreId Dinámico (1 min)
**Ubicación**: `add_location_page.dart` → Crear ubicación

**Pasos**:
1. Ve a `Locations`
2. Click "+ Agregar Ubicación"
3. Completa form
4. Click "Guardar"
5. ✅ Si se crea sin error → RESUELTO
6. ❌ Si sale error → El storeId es null

**Validación Backend**:
```bash
# Verifica en MongoDB que location.storeId es tu tienda actual
# No debe ser: 000000000000000000000001
```

---

## TEST 4: Icono WhatsApp (30 seg)
**Ubicación**: `supplier_list_page.dart`

**Pasos**:
1. Ve a `Suppliers`
2. Mira el ícono del botón de WhatsApp
3. ✅ Si es icono de **mensaje/chat** → RESUELTO
4. ❌ Si es otro icono → No se aplicó cambio

---

## TEST 5: Conectividad Backend (1 min)
**Ubicación**: Terminal / Backend

**Pasos**:
```bash
# En bellezapp-backend/
npm run dev

# Debe mostrar:
# [nodemon] 3.0.1
# [nodemon] watching path(s): src/**/*.ts
# [nodemon] watching extensions: ts,json
# Server is running on http://localhost:3000

# Si error, ejecuta:
lsof -i :3000  # Ver qué ocupa puerto
# O en Windows:
netstat -ano | findstr :3000
```

5. ✅ Si ves "Server is running on port 3000" → RESUELTO
6. ❌ Si error → MongoDB no está corriendo

---

## TEST 6: Notificación QR (2-3 min)
**Ubicación**: `product_list_page.dart` → Generar QR

**Requisito**: 
- Android 13+
- App compilada en `release` o `profile`

**Pasos**:
1. Abre `Product List`
2. Click en un producto
3. Click "📱 Generar QR"
4. En popup: Click "💾 Guardar en Descargas"
5. **IMPORTANTE**: Si aparece dialog de permiso → **ACEPTA**
6. Espera 2 seg
7. Abre notification center (desliza desde arriba)
8. ✅ Si ves "📥 QR Descargado: [filename]" → RESUELTO
9. ❌ Si no ves nada → Revisa logs:

```bash
# Ver logs de notificación:
flutter logs | grep -i "[NOTIF]"

# Busca especialmente:
# [NOTIF] Permiso de notificación otorgado: true/false
# [NOTIF] ✅ Notificación mostrada exitosamente
```

**Debugging si no funciona**:
```bash
# 1. Verifica permisos en Android
adb shell dumpsys package com.example.bellezapp | grep -i notif

# 2. Mira todos los logs:
flutter logs | tail -50

# 3. Borra caché y reinstala:
flutter clean
flutter pub get
flutter run --release
```

---

## 📊 Tabla Rápida de Verificación

| # | Función | Ubicación | Verificación | ✅/❌ |
|---|---------|-----------|--------------|-------|
| 1 | Precio ≠ 0.00 | add_order_page | Escanea QR, ve precio |  |
| 2 | Stock actualiza | product_list_page | Vende producto, stock baja |  |
| 3 | StoreId dinámico | add_location_page | Crea location, sin error |  |
| 4 | Icono correcto | supplier_list_page | Icono es de mensaje |  |
| 5 | Backend corriendo | Backend terminal | npm run dev funciona |  |
| 6 | Notificación QR | product_list_page | Guarda QR, aparece notif |  |

---

## 🚨 Si Algo Falla

### Paso 1: Recolectar Logs
```bash
flutter logs > logs.txt
# Ejecuta el test fallido
# CTRL+C después de 30 seg
# Busca en logs.txt con tu editor
```

### Paso 2: Verificar Cambios
```bash
# En bellezapp/
git diff lib/pages/  # Ver cambios

# En bellezapp-backend/
git diff src/controllers/product.controller.ts
```

### Paso 3: Limpiar y Reintentar
```bash
# Mobile:
flutter clean && flutter pub get && flutter run

# Backend:
npm run dev
```

### Paso 4: Si aún falla
- Revisa el archivo NOTIFICACIONES_QR_GUIA.md para debugging detallado
- Revisa RESUMEN_SESION_FINAL.md para detalles técnicos
- Busca en los logs el patrón `[NOTIF]` o `[ERROR]`

---

## ✅ Confirmación Final

Una vez hayas verificado todo:

```bash
# Terminal:
echo "Versión Backend:"
npm --version

echo "Versión Flutter:"
flutter --version

echo "Versión Dart:"
dart --version

# Abre esta sesión de documentación:
# - NOTIFICACIONES_QR_GUIA.md
# - RESUMEN_SESION_FINAL.md
```

¡Todos los tests completados? → **¡Sistema Listo para Producción!**

---

**Última actualización**: Sesión actual  
**Tiempo estimado de verificación**: 10 minutos  
**Dificultad**: Bajo
