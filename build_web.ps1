# Build Flutter web evitando la carpeta build dentro de OneDrive (fallo con shaders/ink_sparkle.frag).
# Uso: .\build_web.ps1
# Salida: C:\temp\web_evaluacion_build (y opcionalmente build\web para Firebase local).

$outDir = "C:\temp\web_evaluacion_build"
Write-Host "Compilando Flutter web hacia $outDir ..." -ForegroundColor Cyan
flutter build web --output $outDir
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Build OK. Para desplegar: copia el contenido de $outDir a build\web y ejecuta 'firebase deploy --only hosting'." -ForegroundColor Green
# Opcional: copiar a build/web para firebase deploy desde este proyecto
$buildWeb = "build\web"
if (Test-Path $buildWeb) { Remove-Item -Recurse -Force $buildWeb }
New-Item -ItemType Directory -Path $buildWeb -Force | Out-Null
Copy-Item -Path "$outDir\*" -Destination $buildWeb -Recurse -Force
Write-Host "Copiado a $buildWeb. Ya puedes ejecutar: firebase deploy --only hosting" -ForegroundColor Green
