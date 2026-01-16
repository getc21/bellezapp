# 🔧 GUÍA DE FIXES - CRITICAL QA ISSUES

**Documento**: Instrucciones paso a paso para corregir issues críticos  
**Fecha**: 16 de Enero, 2026  
**Duración estimada**: 1.5 horas

---

## 🚀 QUICK START

```bash
# 1. Abrir proyecto
cd C:\Users\raque\OneDrive\Documentos\Proyectos\bellezapp

# 2. Abrir en VS Code
code .

# 3. Buscar y reemplazar los problemas según pasos a continuación
```

---

## 🔴 FIX #1: Non-Null Assertion en product_list_page.dart

### Ubicación
```
Archivo: lib/pages/product_list_page.dart
Línea: 579
Tipo: unnecessary_non_null_assertion
Severidad: CRÍTICO
```

### Paso 1: Localizar el problema
1. [ ] Abrir archivo: `lib/pages/product_list_page.dart`
2. [ ] Presionar `Ctrl+G` (Go to Line)
3. [ ] Ingresar: `579`
4. [ ] Presionar Enter

### Paso 2: Identificar contexto
Buscar código similar a:
```dart
setState(() {
  selectedProduct = products.firstWhere(
    (p) => p.id == productId,
    orElse: () => null!,  // ❌ AQUÍ ESTÁ EL PROBLEMA
  );
});
```

O alternativa:
```dart
var product = products.firstWhere(...);
// Luego usado con ! sin validación
```

### Paso 3: Aplicar fix

**Opción A: Si usa orElse null!**
```dart
// ❌ ANTES
setState(() {
  selectedProduct = products.firstWhere(
    (p) => p.id == productId,
    orElse: () => null!,  // Problema
  );
});

// ✅ DESPUÉS
setState(() {
  final product = products.firstWhereOrNull(
    (p) => p.id == productId,
  );
  if (product != null) {
    selectedProduct = product;
  }
});
```

**Opción B: Si usa ! after method**
```dart
// ❌ ANTES
if (products.isNotEmpty) {
  final p = products.firstWhere(...)!;  // Problema
}

// ✅ DESPUÉS
if (products.isNotEmpty) {
  final p = products.firstWhere(
    (item) => item.id == targetId,
    orElse: () => products.first,
  );
  // Ahora es seguro sin !
}
```

### Paso 4: Validar fix
- [ ] Sin warning en el editor
- [ ] Presionar `Ctrl+Shift+P`
- [ ] Escribir "Dart: Analyze"
- [ ] Verificar que el warning desaparece

### ✅ Tiempo estimado: 15 minutos

---

## 🔴 FIX #2: BuildContext Across Async (expense_report_page.dart)

### Ubicación
```
Archivo: lib/pages/expense_report_page.dart
Líneas: 111, 127, 137, 166, 178, 189, 190
Tipo: use_build_context_synchronously
Severidad: CRÍTICO (7 casos)
```

### Paso 1: Abrir archivo
1. [ ] Abrir: `lib/pages/expense_report_page.dart`
2. [ ] Presionar `Ctrl+H` (Find and Replace)

### Paso 2: Buscar patrón problemático
Buscar cada línea de los problemas:
- Línea 111: `context.go` o `Navigator.push` dentro de await
- Línea 127: Similar
- etc.

### Paso 3: Pattern de Fix General

**Patrón Problemático**:
```dart
Future<void> _deleteExpense(String id) async {
  final success = await apiCall.delete(id);
  
  // ❌ PELIGRO: context usado después de await
  if (success) {
    context.go('/expenses');  // Línea 111 ej.
  }
}
```

**Fix Aplicado**:
```dart
Future<void> _deleteExpense(String id) async {
  final success = await apiCall.delete(id);
  
  // ✅ SEGURO: Check mounted antes de usar context
  if (mounted && success) {
    context.go('/expenses');
  }
}
```

### Paso 4: Aplicar a cada línea problemática

**Línea 111**:
```dart
// ❌ ANTES
final result = await controller.someAsync();
context.go('/somewhere');

// ✅ DESPUÉS
final result = await controller.someAsync();
if (mounted) {
  context.go('/somewhere');
}
```

**Línea 127**:
```dart
// ❌ ANTES
Navigator.pop(context);

// ✅ DESPUÉS
if (mounted) {
  Navigator.pop(context);
}
```

**Línea 137, 166, 178, 189, 190**:
Aplicar el mismo patrón: `if (mounted) { context... }`

### Paso 5: Validación

Para cada línea corregida:
1. [ ] Envuelto en `if (mounted) { ... }`
2. [ ] Sin error en editor
3. [ ] BuildContext usado de forma segura

### Checklist de Líneas Corregidas
```
□ Línea 111 ✓
□ Línea 127 ✓
□ Línea 137 ✓
□ Línea 166 ✓
□ Línea 178 ✓
□ Línea 189 ✓
□ Línea 190 ✓
```

### ✅ Tiempo estimado: 45 minutos

---

## 🟡 OPTIONAL FIX #3: Print Statements (product_provider.dart)

**Líneas**: 304, 311, 312, 325  
**Severidad**: MENOR  
**Impacto**: Debugging mejorado

### Fix:
```dart
// ❌ ANTES
print('Cargando productos...');

// ✅ DESPUÉS
debugPrint('Cargando productos...');
```

O usar logger:
```dart
import 'package:flutter/foundation.dart';

debugPrint('Mensaje');  // Solo en debug
```

**Tiempo**: 15 minutos (opcional)

---

## 🟡 OPTIONAL FIX #4: Code Style Issues

### Issue: sort_child_properties_last
**Líneas**: inventory_rotation_page.dart:208, periods_comparison_page.dart:278, etc.

```dart
// ❌ ANTES
Widget(
  child: myChild,
  padding: EdgeInsets.all(8),
)

// ✅ DESPUÉS
Widget(
  padding: EdgeInsets.all(8),
  child: myChild,
)
```

**Tiempo**: 20 minutos (opcional)

---

## 🔍 PASO FINAL: VALIDACIÓN

### 1. Verificar Análisis
```bash
cd C:\Users\raque\OneDrive\Documentos\Proyectos\bellezapp
flutter analyze
```

**Resultado esperado**:
```
Analyzing bellezapp...

(Deberían desaparecer los 2 issues críticos)

X issues found. (antes eran 22)
```

### 2. Recompilar APK
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

**Resultado esperado**:
```
√ Built build\app\outputs\flutter-apk\app-debug.apk
```

### 3. Verificar en Editor
- [ ] Abrir los archivos modificados
- [ ] No hay warnings rojos
- [ ] Código se ve limpio

---

## 📋 CHECKLIST DE COMPLETITUD

### Fixes Críticos
- [ ] Non-null assertion removida
- [ ] BuildContext mounted checks agregados (7 casos)
- [ ] flutter analyze limpio (sin los 2 críticos)
- [ ] APK compila exitosamente

### Validación
- [ ] Sin errores en compilación
- [ ] Sin warnings en editor
- [ ] Código formateado correctamente

### Testing Previo (Smoke Test)
- [ ] Instalar APK
- [ ] App abre sin crashes
- [ ] Navegar a expense_report_page
- [ ] Sin errores de BuildContext

---

## 🎯 PRÓXIMOS PASOS DESPUÉS DE FIXES

1. ✅ **Commit cambios a Git**
   ```bash
   git add -A
   git commit -m "QA: Fix critical BuildContext and null assertion issues"
   git push
   ```

2. 📱 **Instalar en dispositivo**
   ```bash
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```

3. 🧪 **Ejecutar testing**
   - Seguir QA_TESTING_CHECKLIST.md
   - Documentar resultados

4. 📊 **Reportar resultados**
   - Actualizar QA_TESTING_REPORT.md
   - Enviar a stakeholders

---

## 💡 TIPS ÚTILES

### VS Code Shortcuts
```
Ctrl+G     = Go to Line
Ctrl+H     = Find and Replace
Ctrl+F     = Find
Alt+Up/Down = Move línea
Ctrl+K Ctrl+F = Format documento
```

### Flutter Commands
```
flutter analyze              = Check code quality
flutter format .            = Format all files
flutter clean               = Clean build
flutter pub outdated        = Check dependency versions
```

### Debugging
```dart
debugPrint('mensaje');  // Solo en debug
if (kDebugMode) { print('debug only'); }
```

---

## ❓ FAQ

**P: ¿Qué es `mounted`?**  
R: Es una propiedad que indica si el widget está en el árbol de widgets. Es false después de `dispose()`. Debemos verificarlo antes de usar `context`.

**P: ¿Por qué firstWhere!() es peligroso?**  
R: El `!` fuerza la conversión a no-null, pero si `firstWhere` lanza excepción, puede crashear. Usar `orElse` es más seguro.

**P: ¿Cuándo debo usar `if (mounted)`?**  
R: Siempre que uses `context` después de un `await` o dentro de un callback que se ejecuta de forma asincrónica.

**P: ¿El APK necesita ser reinstalado?**  
R: Sí, después de compilar, desinstalar la versión anterior y reinstalar la nueva.

---

**Documentado por**: QA Professional  
**Última actualización**: 16 de Enero, 2026

