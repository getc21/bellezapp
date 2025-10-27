# Migración v11: Store ID en Módulos Financieros

## 📋 Resumen
Migración de base de datos de versión 10 a 11 para agregar `store_id` a las tablas financieras y de caja, completando así el sistema multi-tienda.

## 🎯 Objetivo
Separar completamente los datos financieros y de caja por tienda, permitiendo reportes y gestión independiente de cada sucursal.

## 📊 Cambios en el Schema

### Tablas Modificadas

#### 1. `financial_transactions`
**Antes:**
```sql
CREATE TABLE financial_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT,
  type TEXT,
  amount REAL
)
```

**Después:**
```sql
CREATE TABLE financial_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT,
  type TEXT,
  amount REAL,
  store_id INTEGER DEFAULT 1,
  FOREIGN KEY (store_id) REFERENCES stores(id)
)
```

#### 2. `cash_movements`
**Antes:**
```sql
CREATE TABLE cash_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  description TEXT,
  order_id INTEGER,
  user_id TEXT,
  FOREIGN KEY (order_id) REFERENCES orders (id)
)
```

**Después:**
```sql
CREATE TABLE cash_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  description TEXT,
  order_id INTEGER,
  user_id TEXT,
  store_id INTEGER DEFAULT 1,
  FOREIGN KEY (order_id) REFERENCES orders (id),
  FOREIGN KEY (store_id) REFERENCES stores(id)
)
```

#### 3. `cash_registers`
**Antes:**
```sql
CREATE TABLE cash_registers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  opening_amount REAL NOT NULL,
  closing_amount REAL,
  expected_amount REAL,
  difference REAL,
  status TEXT NOT NULL,
  opening_time TEXT,
  closing_time TEXT,
  user_id TEXT
)
```

**Después:**
```sql
CREATE TABLE cash_registers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  opening_amount REAL NOT NULL,
  closing_amount REAL,
  expected_amount REAL,
  difference REAL,
  status TEXT NOT NULL,
  opening_time TEXT,
  closing_time TEXT,
  user_id TEXT,
  store_id INTEGER DEFAULT 1,
  FOREIGN KEY (store_id) REFERENCES stores(id)
)
```

## 🔧 Métodos Actualizados

### Métodos de Inserción (INSERT)
Ahora automáticamente agregan `store_id` de la tienda actual:

1. ✅ `insertProduct()` - Agrega store_id al producto Y a la transacción financiera
2. ✅ `insertCashMovement()` - Agrega store_id del contexto actual
3. ✅ `insertCashRegister()` - Agrega store_id de la tienda actual
4. ✅ `addProductStock()` - Transacción financiera con store_id

### Métodos de Consulta (SELECT)
Ahora filtran por `store_id` de la tienda actual:

1. ✅ `getFinancialDataForLastYear()` - Filtra gastos por tienda
2. ✅ `getFinancialDataBetweenDates()` - Filtra gastos por tienda
3. ✅ `getCashMovementsByDate()` - Filtra movimientos por tienda
4. ✅ `getTotalCashByTypeAndDate()` - Suma solo de la tienda actual
5. ✅ `getCashRegisterByDate()` - Busca caja de la tienda actual

## 🚀 Migración Automática

Cuando la app se inicie con la nueva versión, se ejecutará automáticamente:

```sql
ALTER TABLE financial_transactions ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id);
ALTER TABLE cash_movements ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id);
ALTER TABLE cash_registers ADD COLUMN store_id INTEGER DEFAULT 1 REFERENCES stores(id);
```

**Datos existentes:** Se asignarán automáticamente a `store_id = 1` (Tienda Principal)

## 📦 Tablas por Alcance

### ✅ Tablas CON store_id (Datos por tienda):
- `products` - Productos específicos de cada tienda
- `orders` - Órdenes de cada tienda
- `financial_transactions` - Transacciones financieras por tienda ✨ **NUEVO**
- `cash_movements` - Movimientos de caja por tienda ✨ **NUEVO**
- `cash_registers` - Cajas registradoras por tienda ✨ **NUEVO**

### 🌐 Tablas SIN store_id (Recursos globales compartidos):
- `categories` - Categorías compartidas
- `suppliers` - Proveedores compartidos
- `locations` - Ubicaciones compartidas
- `customers` - Clientes compartidos
- `discounts` - Descuentos globales
- `users` - Usuarios del sistema
- `roles` - Roles del sistema
- `user_store_assignments` - Asignaciones usuario-tienda

## ⚠️ Cambios Importantes

### 1. Categorías, Proveedores y Ubicaciones
- **CORRECCIÓN:** Se removió el intento de agregar `store_id` a estas tablas
- **Razón:** Estas tablas NO tienen columna `store_id` en el schema
- **Comportamiento:** Son recursos compartidos entre todas las tiendas

### 2. Método `_isAdmin()` Eliminado
- **Motivo:** No se usaba en ningún lugar
- **Reemplazo:** Los métodos ahora SIEMPRE filtran por tienda actual

## 🎨 Impacto en la UI

### Reportes Financieros
- ✅ Ahora muestran datos solo de la tienda seleccionada
- ✅ Gráficas de ingresos/gastos separadas por tienda
- ✅ Balance financiero independiente por sucursal

### Sistema de Caja
- ✅ Cada tienda tiene su propia caja independiente
- ✅ Arqueos de caja separados por tienda
- ✅ Movimientos de efectivo filtrados por sucursal

### Dashboard
- ✅ Métricas financieras específicas de la tienda actual
- ✅ Total de ventas por tienda
- ✅ Gastos operativos por tienda

## 🔍 Testing Recomendado

1. **Crear dos tiendas diferentes**
2. **Crear productos en cada tienda** → Verificar transacciones financieras separadas
3. **Hacer ventas en ambas tiendas** → Verificar movimientos de caja independientes
4. **Abrir caja en ambas tiendas** → Verificar cajas registradoras separadas
5. **Ver reportes financieros** → Verificar datos filtrados por tienda
6. **Cambiar entre tiendas** → Verificar que los datos cambian correctamente

## 📝 Notas Técnicas

### Helper Method `_getCurrentStoreId()`
Este método obtiene el ID de la tienda actual desde `StoreController`:
```dart
int _getCurrentStoreId() {
  try {
    final storeController = Get.find<StoreController>();
    return storeController.currentStoreId ?? 1;
  } catch (e) {
    return 1; // Fallback a tienda principal
  }
}
```

### Manejo de Datos de Prueba
Los datos de prueba generados en `_insertTestData()` se asignan a `store_id = 1`

## ✅ Completado

- [x] Actualizar versión de DB a 11
- [x] Agregar `store_id` a `financial_transactions` (schema + migración)
- [x] Agregar `store_id` a `cash_movements` (schema + migración)
- [x] Agregar `store_id` a `cash_registers` (schema + migración)
- [x] Actualizar métodos INSERT para incluir `store_id`
- [x] Actualizar métodos SELECT para filtrar por `store_id`
- [x] Remover código obsoleto (`_isAdmin()`)
- [x] Corregir intentos de agregar `store_id` a tablas globales
- [x] Validar que no hay errores de compilación

## 🎯 Estado Final

**Sistema Multi-Tienda 100% Completo** ✅

Todas las tablas de datos de negocio ahora están correctamente separadas por tienda:
- ✅ Inventario (productos)
- ✅ Ventas (orders)
- ✅ Finanzas (financial_transactions)
- ✅ Caja (cash_movements, cash_registers)

Los recursos compartidos permanecen globales:
- ✅ Catálogos (categorías, proveedores, ubicaciones)
- ✅ Clientes
- ✅ Usuarios y permisos

---
**Fecha:** 27 de octubre de 2025
**Versión DB:** 10 → 11
**Estado:** ✅ Completado
