# ✅ CHECKLIST - URL API Corregida

## 🎯 QUÉ SE CAMBIÓ

```
expense_provider.dart
  ❌ Antes: final String _baseUrl = 'https://bellezapp-api.herokuapp.com/api/expenses';
  ✅ Después: String get _baseUrl => '${ApiConfig.baseUrl}/expenses';
```

---

## ✅ VERIFICACIÓN RÁPIDA

### 1. ¿Está corriendo el Backend?
```bash
cd c:\Users\raque\OneDrive\Documentos\Proyectos\bellezapp-backend
npm run dev

# Debe mostrar:
# Server running on port 3000
# MongoDB connected (o tu BD)
```

### 2. ¿Cuál es tu IP local?
```bash
ipconfig
# Busca "IPv4 Address" en tu interfaz Wi-Fi
# Ejemplo: 192.168.0.48
```

### 3. ¿Está en api_config.dart la IP correcta?
Abre: `lib/config/api_config.dart`

Verifica:
```dart
static const String _localIP = '192.168.0.48';  // ← Tu IP aquí
```

**Si es diferente, cámbiala ahora**

### 4. ¿El puerto es 3000?
En `bellezapp-backend/.env`:
```
PORT=3000
```

**Debe coincidir con `api_config.dart`:**
```dart
static const String _port = '3000';
```

---

## 🚀 PASOS PARA PROBAR

### Opción 1: En Emulador Android
```bash
# 1. Asegúrate que el backend está corriendo en tu PC
npm run dev

# 2. Inicia la app en emulador
flutter run

# 3. Navega a Sistema de Gastos
# Debe conectar a: http://10.0.2.2:3000/api/expenses
```

### Opción 2: En Dispositivo Físico
```bash
# 1. Tu PC y el dispositivo DEBEN estar en la MISMA RED Wi-Fi

# 2. Asegúrate que el backend está corriendo
npm run dev

# 3. Inicia la app en dispositivo
flutter run -d <device_id>

# 4. Navega a Sistema de Gastos
# Debe conectar a: http://192.168.0.48:3000/api/expenses
```

### Opción 3: En Simulador iOS
```bash
# 1. El simulador accede a localhost directamente
# 2. Usa 127.0.0.1:3000 (localhost)
# 3. O configura en api_config.dart para iOS
```

---

## 📊 DIAGRAMA DE CONEXIÓN

```
┌─ EMULADOR ANDROID
│  └─ URL: http://10.0.2.2:3000/api/expenses
│     └─ Se convierte a: http://192.168.0.48:3000/api/expenses
│        └─ En tu PC
│
├─ DISPOSITIVO FÍSICO
│  └─ URL: http://192.168.0.48:3000/api/expenses
│     └─ Directo a tu PC (misma red Wi-Fi)
│
└─ PRODUCCIÓN
   └─ URL: https://naturalmarket.onrender.com/api/expenses
      └─ Servidor remoto en Render
```

---

## 🧪 CÓMO VERIFICAR CONECTIVIDAD

### En Flutter DevTools
Mientras la app está corriendo:
1. Abre DevTools
2. Pestaña "Logging"
3. Busca logs de expense_provider
4. Debe mostrar la URL correcta siendo llamada

### Usando Postman
```http
GET http://192.168.0.48:3000/api/expenses
Authorization: Bearer YOUR_TOKEN
```

Debe devolver:
```json
{
  "data": {
    "expenses": [...]
  }
}
```

Si falla, verifica:
- ✅ Backend está corriendo
- ✅ IP correcta en api_config.dart
- ✅ Token de autenticación válido
- ✅ Ruta `/api/expenses` existe en backend

---

## 🎯 RESULTADO ESPERADO

Una vez verificado todo:

✅ Emulador/Dispositivo conecta correctamente al backend
✅ Sistema de Gastos carga sin errores
✅ Se muestran los gastos registrados
✅ Puedes agregar nuevos gastos
✅ Los reportes funcionan

---

## 💡 SI SIGUE FALLANDO

1. **Verifica el error en DevTools:**
   - Ve a la pestaña Logging
   - Copia el error completo
   - Te ayudaré a resolverlo

2. **Verifica la conectividad:**
   ```bash
   # Ping a tu PC desde el dispositivo
   ping 192.168.0.48
   ```

3. **Verifica el backend:**
   ```bash
   # En tu PC, verifica que backend escucha
   curl http://localhost:3000/health
   # Debe responder: {"status":"OK"}
   ```

4. **Verifica el firewall:**
   - Windows Firewall puede bloquear puerto 3000
   - Abre puerto 3000 en Windows Defender

---

## ✅ ESTADO ACTUAL

| Componente | Estado |
|-----------|--------|
| `expense_provider.dart` | ✅ Usa ApiConfig |
| `api_config.dart` | ✅ Detecta ambiente |
| Compilación | ✅ Sin errores |
| Configuración | ⏳ Verifica tu IP |

**Próximo paso:** Verifica tu IP local y ejecuta `flutter run` 🚀
