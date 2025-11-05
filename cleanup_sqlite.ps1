# Script para eliminar código SQLite de Bellezapp
# ⚠️ EJECUTAR SOLO DESPUÉS DE PROBAR QUE TODO FUNCIONA CON REST API

Write-Host "🗑️  Eliminando código SQLite..." -ForegroundColor Red
Write-Host "⚠️  Asegúrate de haber probado todas las funciones antes de continuar" -ForegroundColor Yellow
Write-Host ""

$confirmation = Read-Host "¿Estás seguro de querer eliminar el código SQLite? (escribe 'SI' para confirmar)"

if ($confirmation -ne "SI") {
    Write-Host "❌ Operación cancelada" -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "📦 Creando backup antes de eliminar..." -ForegroundColor Cyan

# Crear carpeta de backup
$backupDir = "backup_sqlite_" + (Get-Date -Format "yyyyMMdd_HHmmss")
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Archivos a eliminar
$filesToDelete = @(
    "lib/database/database_helper.dart",
    "lib/services/auth_service.dart",
    "web/sqflite_sw.js"
)

$deleted = 0
$notFound = 0

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        # Hacer backup
        $backupPath = Join-Path $backupDir $file
        $backupParent = Split-Path $backupPath -Parent
        New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
        Copy-Item -Path $file -Destination $backupPath -Force
        
        # Eliminar
        Remove-Item -Path $file -Force
        Write-Host "✅ Eliminado: $file (backup en $backupDir)" -ForegroundColor Green
        $deleted++
    }
    else {
        Write-Host "⚠️  No encontrado: $file" -ForegroundColor Yellow
        $notFound++
    }
}

# Archivos _old.dart opcionales
Write-Host ""
Write-Host "🔍 Buscando archivos *_old.dart..." -ForegroundColor Cyan
$oldFiles = Get-ChildItem "lib/pages/*_old.dart" -ErrorAction SilentlyContinue

if ($oldFiles) {
    Write-Host "Encontrados $($oldFiles.Count) archivos antiguos:" -ForegroundColor Yellow
    foreach ($file in $oldFiles) {
        Write-Host "   - $($file.Name)" -ForegroundColor Gray
    }
    
    $deleteOld = Read-Host "¿Eliminar estos archivos? (S/N)"
    if ($deleteOld -eq "S" -or $deleteOld -eq "s") {
        foreach ($file in $oldFiles) {
            # Backup
            $backupPath = Join-Path $backupDir "lib/pages/$($file.Name)"
            Copy-Item -Path $file.FullName -Destination $backupPath -Force
            
            # Eliminar
            Remove-Item -Path $file.FullName -Force
            Write-Host "✅ Eliminado: $($file.Name)" -ForegroundColor Green
            $deleted++
        }
    }
}

# Editar pubspec.yaml
Write-Host ""
Write-Host "📝 Editando pubspec.yaml..." -ForegroundColor Cyan

if (Test-Path "pubspec.yaml") {
    # Hacer backup
    Copy-Item -Path "pubspec.yaml" -Destination (Join-Path $backupDir "pubspec.yaml") -Force
    
    # Leer contenido
    $content = Get-Content "pubspec.yaml" -Raw
    
    # Eliminar línea de sqflite
    $newContent = $content -replace '[\r\n]+\s*sqflite:\s*\^[\d\.]+[\r\n]+', "`n"
    
    # Guardar
    Set-Content -Path "pubspec.yaml" -Value $newContent -NoNewline
    Write-Host "✅ Eliminada dependencia 'sqflite' de pubspec.yaml" -ForegroundColor Green
}
else {
    Write-Host "❌ No se encontró pubspec.yaml" -ForegroundColor Red
}

# Eliminar carpeta database si está vacía
Write-Host ""
Write-Host "📁 Verificando carpeta lib/database..." -ForegroundColor Cyan

if (Test-Path "lib/database") {
    $filesInDatabase = Get-ChildItem "lib/database" -Recurse -File
    if ($filesInDatabase.Count -eq 0) {
        Remove-Item -Path "lib/database" -Recurse -Force
        Write-Host "✅ Eliminada carpeta lib/database (estaba vacía)" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Carpeta lib/database aún contiene archivos:" -ForegroundColor Yellow
        foreach ($file in $filesInDatabase) {
            Write-Host "   - $($file.Name)" -ForegroundColor Gray
        }
    }
}

# Resumen
Write-Host ""
Write-Host "📊 Resumen:" -ForegroundColor Cyan
Write-Host "   Archivos eliminados: $deleted" -ForegroundColor Green
Write-Host "   Archivos no encontrados: $notFound" -ForegroundColor Yellow
Write-Host "   Backup guardado en: $backupDir" -ForegroundColor Cyan

Write-Host ""
Write-Host "🎉 ¡Limpieza completada!" -ForegroundColor Green
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Cyan
Write-Host "1. Ejecutar: flutter clean" -ForegroundColor White
Write-Host "2. Ejecutar: flutter pub get" -ForegroundColor White
Write-Host "3. Ejecutar: flutter run" -ForegroundColor White
Write-Host "4. Verificar que no hay errores de compilación" -ForegroundColor White
Write-Host "5. Probar todas las funcionalidades" -ForegroundColor White
Write-Host "6. Si todo funciona, puedes eliminar la carpeta $backupDir" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Si hay problemas, restaura desde $backupDir" -ForegroundColor Yellow
