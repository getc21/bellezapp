# Migración v12: Store ID en Tabla Locations

## 📋 Resumen
Migración de base de datos de versión 11 a 12 para agregar `store_id` a la tabla `locations`, haciendo que las ubicaciones sean específicas de cada tienda en lugar de compartidas.

## 🎯 Objetivo
Las ubicaciones físicas (Estante A, Bodega, Vitrina 1, etc.) son específicas de cada tienda, por lo que cada sucursal debe tener su propio conjunto de ubicaciones independiente.

## 📊 Cambios en el Schema

### Tabla Modificada: `locations`

**Antes:**
```sql
CREATE TABLE locations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT
)
```

**Después:**
```sql
CREATE TABLE locations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  store_id INTEGER DEFAULT 1,
  FOREIGN KEY (store_id) REFERENCES stores(id)
)
```

## 🔧 Métodos Actualizados

### Método de Inserción (INSERT)
Ahora automáticamente agrega `store_id` de la tienda actual:

```dart
Future<void> insertLocation(Map<String, dynamic> location) async {
  final db = await database;
  
  // Las ubicaciones son específicas de cada tienda
  if (!location.containsKey('store_id')) {
    location['store_id'] = _getCurrentStoreId();
  }
  
  await db.insert('locations', location);
}
```

### Método de Consulta (SELECT)
Ahora filtra por `store_id` de la tienda actual:

```dart
Future<List<Map<String, dynamic>>> getLocations() async {
  final db = await database;
  final currentStoreId = _getCurrentStoreId();
  
  return await db.query(
    'locations',
    where: 'store_id = ?',
    whereArgs: [currentStoreId],
  );
}
```

### Método de Consulta de Productos por Ubicación
También actualizado para filtrar por tienda:

```dart
Future<List<Map<String, dynamic>>> getProductsByLocation(int locationId) async {
  final db = await database;
  final currentStoreId = _getCurrentStoreId();
  
  return await db.rawQuery('''
    SELECT p.*, 
           c.name as category_name, 
           s.name as supplier_name, 
           l.name as location_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN suppliers s ON p.supplier_id = s.id
    LEFT JOIN locations l ON p.location_id = l.id
    WHERE p.location_id = ? AND p.store_id = ?
  ''', [locationId, currentStoreId]);
}
```

## 🚀 Migración Automática

Cuando la app se inicie con la nueva versión, se ejecutará automáticamente:

```sql
ALTER TABLE locations ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id);
```

**Datos existentes:** Se asignarán automáticamente a `store_id = 1` (Tienda Principal)

## 📦 Arquitectura Final de Datos

### ✅ Tablas CON store_id (Datos por tienda):
- `products` - Productos específicos de cada tienda
- `orders` - Órdenes de cada tienda
- `financial_transactions` - Transacciones financieras por tienda
- `cash_movements` - Movimientos de caja por tienda
- `cash_registers` - Cajas registradoras por tienda
- `locations` - Ubicaciones físicas por tienda ✨ **NUEVO**

### 🌐 Tablas SIN store_id (Recursos globales compartidos):
- `categories` - Categorías de productos compartidas
- `suppliers` - Proveedores compartidos
- `customers` - Clientes compartidos
- `discounts` - Descuentos globales
- `users` - Usuarios del sistema
- `roles` - Roles del sistema
- `user_store_assignments` - Asignaciones usuario-tienda

## 💡 Razón del Cambio

### ❌ Problema Anterior:
Las ubicaciones eran compartidas entre todas las tiendas. Esto causaba:
- **Confusión:** "Estante A" en Tienda Principal ≠ "Estante A" en Sucursal
- **Inconsistencia:** Cada tienda tiene diferente distribución física
- **Datos mezclados:** Al ver productos por ubicación, se mostraban de todas las tiendas

### ✅ Solución Actual:
Cada tienda tiene su propio conjunto de ubicaciones:
- ✅ Tienda Principal puede tener: Vitrina 1, Estante A, Bodega Principal
- ✅ Sucursal Sta.Cruz puede tener: Mostrador, Estante Central, Almacén
- ✅ Cada producto se asigna a una ubicación de SU tienda
- ✅ Al consultar ubicaciones, solo ves las de tu tienda actual

## 🎨 Impacto en la UI

### Gestión de Ubicaciones
- ✅ Al crear ubicación → Se asigna automáticamente a tienda actual
- ✅ Al listar ubicaciones → Solo muestra las de la tienda actual
- ✅ Al editar ubicación → Solo puede editar ubicaciones de su tienda

### Ver Productos por Ubicación
- ✅ Solo muestra productos de esa ubicación EN la tienda actual
- ✅ No hay mezcla de productos de diferentes sucursales
- ✅ Filtrado correcto: ubicación + tienda

### Asignación de Productos
- ✅ Dropdown de ubicaciones solo muestra las de la tienda actual
- ✅ No se pueden asignar ubicaciones de otras tiendas

## 🔍 Ejemplo Práctico

### Antes (Compartido - INCORRECTO):
```
Tienda Principal:
  - Producto "Perfume A" → Ubicación: "Estante A"

Sucursal Sta.Cruz:
  - Producto "Crema B" → Ubicación: "Estante A"  ❌ Misma ubicación, diferente tienda

Problema: "Estante A" aparece en ambas tiendas pero son físicamente diferentes
```

### Después (Por Tienda - CORRECTO):
```
Tienda Principal (store_id=1):
  - Ubicaciones: ["Vitrina Principal", "Estante A", "Bodega Norte"]
  - Producto "Perfume A" → Ubicación: "Estante A" (store_id=1)

Sucursal Sta.Cruz (store_id=2):
  - Ubicaciones: ["Mostrador Central", "Estante Izquierdo", "Almacén"]
  - Producto "Crema B" → Ubicación: "Mostrador Central" (store_id=2)

Beneficio: Cada tienda administra sus propias ubicaciones físicas
```

## 📝 Notas Técnicas

### Por qué Locations SÍ necesita store_id:
- **Ubicaciones físicas:** Se refiere a lugares físicos dentro de cada tienda
- **Distribución diferente:** Cada tienda tiene su propia arquitectura/layout
- **Gestión independiente:** Cada gerente organiza su inventario a su manera

### Por qué Categories y Suppliers NO necesitan store_id:
- **Categorías:** Son conceptos (Perfumes, Cremas, Maquillaje) - universales
- **Proveedores:** Son empresas externas - proveen a todas las sucursales

## ✅ Testing Recomendado

1. **Crear ubicaciones en Tienda Principal**
   - Ejemplo: "Vitrina 1", "Estante A", "Bodega"
   - Verificar que tienen store_id = 1

2. **Cambiar a Sucursal Sta.Cruz**
   - Crear ubicaciones diferentes: "Mostrador", "Almacén"
   - Verificar que tienen store_id = 2
   - Verificar que NO se ven las ubicaciones de Tienda Principal

3. **Crear productos en cada tienda**
   - Asignar a ubicaciones de SU tienda
   - Verificar dropdown solo muestra ubicaciones correctas

4. **Ver productos por ubicación**
   - Seleccionar una ubicación
   - Verificar que solo muestra productos de esa ubicación EN esa tienda

## 📊 Estado del Proyecto

**Sistema Multi-Tienda: 100% Completo** ✅

Todas las tablas de datos están correctamente separadas o compartidas según su naturaleza:

### Datos por Tienda (6 tablas):
1. ✅ Products
2. ✅ Orders
3. ✅ Financial Transactions
4. ✅ Cash Movements
5. ✅ Cash Registers
6. ✅ Locations

### Datos Globales (7 tablas):
1. ✅ Categories
2. ✅ Suppliers
3. ✅ Customers
4. ✅ Discounts
5. ✅ Users
6. ✅ Roles
7. ✅ User Store Assignments

---
**Fecha:** 27 de octubre de 2025
**Versión DB:** 11 → 12
**Cambio:** Locations ahora son específicas por tienda
**Estado:** ✅ Completado y Migrado
