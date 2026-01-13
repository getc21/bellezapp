# 💡 EJEMPLOS PRÁCTICOS - Aplicar Ahora Mismo

## Copia y Pega - Ejemplos Listos para Usar

---

## 1️⃣ InitializablePage - Ejemplo Listo

Si tu página tiene un patrón como este en `initState()`:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_hasInitialized && mounted) {
      _hasInitialized = true;
      // Tu código de carga aquí
    }
  });
}
```

### ✅ Reemplázalo con esto:

```dart
import 'package:bellezapp/mixins/initializable_page_mixin.dart';

class MyPageState extends State<MyPage> with InitializablePage {
  @override
  void initializeOnce() {
    // Tu código de carga aquí
  }

  @override
  Widget build(BuildContext context) {
    // Tu UI aquí
  }
}
```

---

## 2️⃣ ThemeUtils - Ejemplo Listo

### Caso 1: Cambiar colores basados en tema

**ANTES:**
```dart
@override
Widget build(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  final isDark = brightness == Brightness.dark;
  
  final bgColor = isDark ? Colors.grey[900] : Colors.grey[50];
  final textColor = isDark ? Colors.grey[400] : Colors.grey[600];
  final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];
  
  return Container(
    color: bgColor,
    border: Border.all(color: borderColor),
    child: Text('Hello', style: TextStyle(color: textColor)),
  );
}
```

**DESPUÉS:**
```dart
import 'package:bellezapp/utils/theme_utils.dart';

@override
Widget build(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  final isDark = brightness == Brightness.dark;
  
  return Container(
    color: ThemeUtils.getBackgroundColor(isDark),
    border: Border.all(color: ThemeUtils.getBorderColor(isDark)),
    child: Text(
      'Hello', 
      style: TextStyle(color: ThemeUtils.getSecondaryTextColor(isDark))
    ),
  );
}
```

### Caso 2: Card con tema

```dart
import 'package:bellezapp/utils/theme_utils.dart';

class ThemedCard extends StatelessWidget {
  final String title;
  final String content;

  const ThemedCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      color: ThemeUtils.getSurfaceColor(isDark),
      elevation: 4,
      shadowColor: ThemeUtils.getShadowColor(isDark),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: ThemeUtils.getPrimaryTextColor(isDark),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                color: ThemeUtils.getSecondaryTextColor(isDark),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Caso 3: AppBar con tema

```dart
import 'package:bellezapp/utils/theme_utils.dart';

class ThemedAppBar extends AppBar {
  ThemedAppBar({
    required BuildContext context,
    required String title,
  }) : super(
    title: Text(
      title,
      style: TextStyle(
        color: ThemeUtils.getPrimaryTextColor(
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    ),
    backgroundColor: ThemeUtils.getSurfaceColor(
      Theme.of(context).brightness == Brightness.dark,
    ),
    elevation: 1,
  );
}
```

---

## 3️⃣ Buscar y Reemplazar print()

### Si encuentras `print()` en otros archivos:

**BUSCA:**
```
print(
```

**REEMPLAZA CON:**
```dart
if (kDebugMode) debugPrint(
```

**AGREGAA IMPORT (si no está):**
```dart
import 'package:flutter/foundation.dart';
```

### Ejemplo:
```dart
// ANTES
print('User logged in: $username');

// DESPUÉS
if (kDebugMode) debugPrint('User logged in: $username');
```

---

## 4️⃣ Kombinación: InitializablePage + ThemeUtils

Ejemplo completo de una página refactorizada:

```dart
import 'package:bellezapp/mixins/initializable_page_mixin.dart';
import 'package:bellezapp/utils/theme_utils.dart';
import 'package:bellezapp/controllers/product_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> 
    with InitializablePage {
  late ProductController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ProductController>();
  }

  @override
  void initializeOnce() {
    // Se ejecuta automáticamente después del primer frame
    _controller.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(isDark),
      appBar: AppBar(
        title: Text('Productos'),
        backgroundColor: ThemeUtils.getSurfaceColor(isDark),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: _controller.products.length,
          itemBuilder: (context, index) {
            final product = _controller.products[index];
            return Card(
              color: ThemeUtils.getSurfaceColor(isDark),
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  product['name'],
                  style: TextStyle(
                    color: ThemeUtils.getPrimaryTextColor(isDark),
                  ),
                ),
                subtitle: Text(
                  '\$${product['price']}',
                  style: TextStyle(
                    color: ThemeUtils.getSecondaryTextColor(isDark),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
```

---

## 5️⃣ Snippets para VS Code

Si quieres, puedes crear snippets en VS Code:

**Archivo:** `.vscode/dart.code-snippets`

```json
{
  "InitializablePage": {
    "prefix": "initpage",
    "body": [
      "import 'package:bellezapp/mixins/initializable_page_mixin.dart';",
      "",
      "class ${1:MyPageState} extends State<${2:MyPage}> with InitializablePage {",
      "  @override",
      "  void initializeOnce() {",
      "    ${3:// Tu código aquí}",
      "  }",
      "",
      "  @override",
      "  Widget build(BuildContext context) {",
      "    return Scaffold();",
      "  }",
      "}"
    ],
    "description": "Crear página con InitializablePage"
  },
  
  "ThemedContainer": {
    "prefix": "themed",
    "body": [
      "import 'package:bellezapp/utils/theme_utils.dart';",
      "",
      "final isDark = Theme.of(context).brightness == Brightness.dark;",
      "Container(",
      "  color: ThemeUtils.getBackgroundColor(isDark),",
      "  child: Text(",
      "    'Texto',",
      "    style: TextStyle(color: ThemeUtils.getPrimaryTextColor(isDark)),",
      "  ),",
      ");"
    ],
    "description": "Container con ThemeUtils"
  }
}
```

---

## ✅ Checklist Rápido

Aplica estas mejoras inmediatamente:

- [ ] Buscar `print(` en los archivos y reemplazar con `debugPrint`
- [ ] En próximo refactor, aplicar `InitializablePage` a páginas de lista
- [ ] Usar `ThemeUtils` en widgets que tengan colores dinámicos
- [ ] Agregar imports necesarios
- [ ] Testear que todo funciona

---

## 🎯 Impacto Inmediato

| Mejora | Beneficio | Tiempo |
|--------|-----------|--------|
| Buscar print() | Logs limpios | 5 min |
| Usar ThemeUtils | Colores consistentes | 10 min por página |
| Aplicar InitializablePage | Código limpio | 15 min por página |

---

## 📞 Dudas Comunes

**P: ¿Necesito usar estos ahora?**
R: No, son opcionales. Úsalos cuando refactorices o crees código nuevo.

**P: ¿Rompe mi código actual?**
R: No, todo es compatible. Puedes usarlos gradualmente.

**P: ¿Puedo mezclar diferentes patrones?**
R: Sí, perfectamente. Son agnósticos del estado actual.

---

**¡Listo para usar! 🚀**
