# Script para renombrar archivos *_new.dart eliminando el sufijo _new
# Ejecutar desde la raíz del proyecto Flutter (bellezapp)

Write-Host "🔄 Renombrando páginas nuevas (eliminando sufijo _new)..." -ForegroundColor Cyan
Write-Host ""

# Lista de archivos a renombrar
$files = @(
    "lib/pages/product_list_page_new.dart",
    "lib/pages/add_product_page_new.dart",
    "lib/pages/edit_product_page_new.dart",
    "lib/pages/category_list_page_new.dart",
    "lib/pages/add_category_page_new.dart",
    "lib/pages/edit_category_page_new.dart",
    "lib/pages/supplier_list_page_new.dart",
    "lib/pages/add_supplier_page_new.dart",
    "lib/pages/edit_supplier_page_new.dart",
    "lib/pages/location_list_page_new.dart",
    "lib/pages/add_location_page_new.dart",
    "lib/pages/edit_location_page_new.dart",
    "lib/pages/order_list_page_new.dart",
    "lib/pages/sales_history_page_new.dart",
    "lib/pages/category_products_page_new.dart",
    "lib/pages/supplier_products_page_new.dart",
    "lib/pages/location_products_page_new.dart",
    "lib/pages/report_page_new.dart",
    "lib/pages/financial_report_page_new.dart"
)

$renamed = 0
$errors = 0

foreach ($file in $files) {
    if (Test-Path $file) {
        $newName = $file -replace '_new\.dart$', '.dart'
        
        # Si el archivo destino ya existe, hacer backup
        if (Test-Path $newName) {
            $backupName = $newName -replace '\.dart$', '_old.dart'
            Write-Host "⚠️  $newName ya existe, renombrando a $backupName" -ForegroundColor Yellow
            Move-Item -Path $newName -Destination $backupName -Force
        }
        
        try {
            Move-Item -Path $file -Destination $newName
            Write-Host "✅ Renombrado: $file -> $newName" -ForegroundColor Green
            $renamed++
        }
        catch {
            Write-Host "❌ Error renombrando $file : $_" -ForegroundColor Red
            $errors++
        }
    }
    else {
        Write-Host "⚠️  No encontrado: $file" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "📊 Resumen:" -ForegroundColor Cyan
Write-Host "   Archivos renombrados: $renamed" -ForegroundColor Green
Write-Host "   Errores: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })

if ($renamed -gt 0) {
    Write-Host ""
    Write-Host "🎉 ¡Renombrado completado!" -ForegroundColor Green
    Write-Host "📝 Los archivos antiguos se respaldaron con sufijo _old.dart" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor Cyan
    Write-Host "1. Ejecutar: flutter pub get" -ForegroundColor White
    Write-Host "2. Ejecutar: flutter run" -ForegroundColor White
    Write-Host "3. Probar todas las funcionalidades" -ForegroundColor White
    Write-Host "4. Si todo funciona, eliminar archivos *_old.dart" -ForegroundColor White
}
