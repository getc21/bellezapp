# 🧪 GUÍA DE VERIFICACIÓN - Sistema de Gastos

## ✅ Checklist de Compilación

Antes de ejecutar la app, verifica que todo compila:

```bash
# 1. Abre terminal en la carpeta bellezapp
cd c:\Users\raque\OneDrive\Documentos\Proyectos\bellezapp

# 2. Limpia el build anterior
flutter clean

# 3. Obtén las dependencias
flutter pub get

# 4. Compila (sin ejecutar)
flutter pub get && flutter analyze
```

Si no hay errores, puedes continuar.

---

## 🚀 PRUEBAS EN LA APP

### Paso 1: Inicia la App
```bash
flutter run
```

### Paso 2: Navega al Sistema de Gastos
1. Abre el **drawer** (menú lateral)
2. Ve a **Reportes y Análisis**
3. Toca **Sistema de Gastos**

**Esperado:** Ves una pantalla con:
- 📌 Botones de período (Hoy, Semana, Mes, Año, Personalizado)
- 📊 Tarjeta "Total de Gastos"
- 📈 Sección "Gastos por Categoría"
- 💰 Sección "Gastos Principales"

### Paso 3: Registra un Gasto de Prueba
1. Toca el botón **+** en la AppBar
2. **O** Toca **Registrar Gasto** en pantalla
3. Completa:
   - **Monto:** 50 (o cualquier cantidad)
   - **Categoría:** Selecciona una o crea una nueva
   - **Descripción:** "Gasto de prueba"
4. Toca **Registrar Gasto**

**Esperado:**
- ✅ Se muestra "Gasto registrado exitosamente"
- ✅ Vuelves a la pantalla de reportes
- ✅ El gasto aparece en los reportes

### Paso 4: Verifica los Datos
1. El reporte debe mostrar:
   - **Total:** $50.00
   - **Transacciones:** 1
   - **Promedio:** $50.00
2. La categoría debe aparecer en "Gastos por Categoría"
3. El gasto debe aparecer en "Gastos Principales"

### Paso 5: Cambia de Período
1. Toca los botones: "Hoy", "Esta semana", "Este mes", "Este año"
2. Toca **Personalizado** y selecciona un rango de fechas

**Esperado:**
- El reporte se actualiza con cada cambio
- Los números coinciden con el período seleccionado

---

## 🐛 TROUBLESHOOTING

### ❌ "Sin gastos registrados" cuando deberían verse gastos

**Causa:** Backend no devuelve datos

**Soluciones:**
1. Verifica que el backend está corriendo:
   ```bash
   # En terminal del backend
   npm run dev
   ```

2. Verifica la URL del API en `expense_provider.dart`:
   ```dart
   final String _baseUrl = 'https://bellezapp-api.herokuapp.com/api/expenses';
   ```
   
   Debería coincidir con tu API backend.

3. Verifica que tienes token de autenticación válido
   - Asegúrate de haber iniciado sesión
   - Verifica que AuthController tiene token válido

---

### ❌ "Error cargando reporte"

**Causa:** Problema con la solicitud al API

**Soluciones:**
1. Abre **DevTools** en Flutter
2. Busca el error en logs
3. Verifica que el endpoint `/api/expenses/reports` existe en backend

---

### ❌ Botón + no lleva a AddExpensePage

**Causa:** Problema de navegación

**Soluciones:**
1. Verifica el import:
   ```dart
   import 'package:bellezapp/pages/add_expense_page.dart';
   ```

2. Verifica que AddExpensePage existe en `lib/pages/`

---

### ❌ Datos no se actualizan después de agregar gasto

**Causa:** Reactividad GetX no actualizada

**Soluciones:**
1. Abre la app nuevamente
2. El controlador debería recargar automáticamente
3. Si sigue sin funcionar, verifica que `Obx()` envuelve correctamente el UI

---

## 🔍 VERIFICACIÓN TÉCNICA

### En expense_report_page.dart:
```dart
// ✅ Debe tener Obx()
body: RefreshIndicator(
  onRefresh: _loadReport,
  child: Obx(  // ← AQUÍ
    () => SingleChildScrollView(
      ...
    ),
  ),  // ← Y CERRAR AQUÍ
),

// ✅ Debe usar expenseController.isLoading
if (expenseController.isLoading)
  CircularProgressIndicator()

// ✅ Debe tener import correcto
import 'package:bellezapp/pages/add_expense_page.dart';

// ✅ Debe usar Get.to()
Get.to(() => const AddExpensePage());
```

### En expense_controller.dart:
```dart
// ✅ Debe llamar a _loadInitialReport()
@override
void onInit() {
  super.onInit();
  loadExpensesForCurrentStore();
  _loadInitialReport();  // ← AQUÍ
}

// ✅ Debe existir _loadInitialReport()
Future<void> _loadInitialReport() async {
  final currentStore = _storeController.currentStore;
  if (currentStore != null) {
    await loadExpenseReport(
      storeId: currentStore['_id'],
      period: 'monthly',
    );
  }
}
```

---

## 📊 PRUEBA DE CARGA DE DATOS

### Opción 1: En Postman

```http
GET https://bellezapp-api.herokuapp.com/api/expenses/reports?storeId=YOUR_STORE_ID&period=monthly
Authorization: Bearer YOUR_TOKEN
```

**Esperado:**
- Status: 200 OK
- Response: Objeto ExpenseReport con datos

---

### Opción 2: En Flutter Debugger

1. Abre DevTools (mientras app corre)
2. Ve a pestaña Logging
3. Busca mensajes de carga:
   ```
   Loading expense report...
   Expense report loaded: {...}
   ```

---

## ✅ CONCLUSIÓN

Si pasaste todos estos pasos:
- ✅ App inicia sin errores
- ✅ Sistema de Gastos visible
- ✅ Puedes registrar gastos
- ✅ Los gastos aparecen en el reporte
- ✅ Los períodos se actualizan

**¡El Sistema de Gastos funciona perfectamente!** 🎉

---

## 📞 SI ALGO SIGUE SIN FUNCIONAR

1. Verifica la **consola de Flutter** por errores
2. Verifica que bellezapp-backend está corriendo
3. Verifica que tienes datos en la base de datos
4. Verifica que el token de autenticación es válido

Todos los cambios han sido compilados sin errores ✅
