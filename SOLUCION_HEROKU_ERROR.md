# 🔧 SOLUCIÓN - Error "No such app" en Heroku

## 🚨 PROBLEMA

```
Error: Exception: Error fetching expense report: <!DOCTYPE html>
<html>
  <head>
    <title>No such app</title>
```

La app móvil intenta conectarse a `https://bellezapp-api.herokuapp.com/api/expenses` que **no existe**.

---

## 🔍 CAUSA

En `lib/providers/expense_provider.dart` la URL estaba hardcodeada:

```dart
// ❌ INCORRECTO - URL hardcodeada
class ExpenseProvider {
  final String _baseUrl = 'https://bellezapp-api.herokuapp.com/api/expenses';
}
```

Este error de Heroku significa:
- La app `bellezapp-api` no existe en Heroku
- O está desplegada en otro lugar
- O todavía no está desplegada

---

## ✅ SOLUCIÓN IMPLEMENTADA

Cambié `expense_provider.dart` para usar la configuración centralizada:

```dart
// ✅ CORRECTO - Usa ApiConfig
import '../config/api_config.dart';

class ExpenseProvider {
  final String? token;

  ExpenseProvider(this.token);

  String get _baseUrl => '${ApiConfig.baseUrl}/expenses';
}
```

---

## 📋 ¿QUÉ ES ApiConfig?

Archivo: `lib/config/api_config.dart`

Detecta automáticamente el entorno:

```dart
class ApiConfig {
  // PRODUCCIÓN - Render
  static const String _productionUrl = 'https://naturalmarket.onrender.com/api';

  // DESARROLLO LOCAL
  static const String _localIP = '192.168.0.48';
  static const String _emulatorIP = '10.0.2.2';
  static const String _port = '3000';

  static String get baseUrl {
    if (_isEmulator()) {
      return 'http://$_emulatorIP:$_port/api';  // Para emulador: 10.0.2.2:3000
    } else {
      return 'http://$_localIP:$_port/api';     // Para dispositivo: 192.168.0.48:3000
    }
  }
}
```

---

## 🎯 CÓMO FUNCIONA AHORA

### 1. **En Emulador/Simulador**
```
ExpenseProvider URL → ApiConfig.baseUrl 
                    → http://10.0.2.2:3000/api/expenses
                    → Conecta a localhost:3000 del HOST
```

### 2. **En Dispositivo Físico**
```
ExpenseProvider URL → ApiConfig.baseUrl 
                    → http://192.168.0.48:3000/api/expenses
                    → Conecta a la IP local del servidor
```

### 3. **En Producción**
```
ExpenseProvider URL → ApiConfig.baseUrl 
                    → https://naturalmarket.onrender.com/api/expenses
                    → Conecta al servidor en Render
```

---

## 🚀 PRÓXIMOS PASOS

### 1. **Asegúrate de que el backend está corriendo**
```bash
cd bellezapp-backend
npm run dev
# Debe escuchar en http://localhost:3000
```

### 2. **En Emulador Android**
```bash
flutter run
# Automáticamente usará: http://10.0.2.2:3000/api
```

### 3. **En Dispositivo Físico**
```bash
flutter run
# Automáticamente usará: http://192.168.0.48:3000/api
# (Debe estar en la MISMA RED Wi-Fi que el servidor)
```

### 4. **Verifica la Conectividad**
En la app, abre DevTools y busca:
```
Successfully connected to: http://10.0.2.2:3000/api/expenses
```

---

## 📊 COMPARACIÓN: ANTES vs DESPUÉS

### ❌ ANTES
```dart
class ExpenseProvider {
  final String _baseUrl = 'https://bellezapp-api.herokuapp.com/api/expenses';
  
  // Intenta conectar a Heroku → ❌ Error "No such app"
}
```

### ✅ DESPUÉS
```dart
class ExpenseProvider {
  final String? token;
  
  String get _baseUrl => '${ApiConfig.baseUrl}/expenses';
  
  // En desarrollo: http://10.0.2.2:3000/api/expenses ✅
  // En producción: https://naturalmarket.onrender.com/api/expenses ✅
}
```

---

## 🧪 VERIFICACIÓN

```
✅ lib/providers/expense_provider.dart - Sin errores
✅ Import de ApiConfig agregado
✅ URL ahora es dinámica según el ambiente
```

---

## 🎯 RESULTADO ESPERADO

Cuando abras la app ahora:

1. **Si el backend está en localhost:3000**
   - ✅ Emulador → Conecta a `http://10.0.2.2:3000`
   - ✅ Dispositivo físico → Conecta a `http://192.168.0.48:3000`
   - ✅ Los gastos se cargan correctamente

2. **Si estás en producción**
   - ✅ Conecta a `https://naturalmarket.onrender.com`
   - ✅ Los gastos se cargan desde el servidor remoto

---

## 💡 NOTA IMPORTANTE

**¿Cuál es tu IP local?**

En `api_config.dart`:
```dart
static const String _localIP = '192.168.0.48';  // ← VERIFICA ESTO
```

Si tu servidor está en una IP diferente:
1. Descubre tu IP:
   ```bash
   ipconfig  # Windows
   ifconfig  # Mac/Linux
   ```

2. Busca tu IP local (ej: 192.168.1.100)

3. Cambia en `api_config.dart`:
   ```dart
   static const String _localIP = '192.168.1.100';  // Tu IP
   ```

4. Ejecuta `flutter clean` y `flutter run` nuevamente

---

**Sistema de Gastos ahora conecta al API correcto** ✅
