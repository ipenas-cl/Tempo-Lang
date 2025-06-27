@echo off
REM Build Tempo Bootstrap para Windows - CERO C
REM Author: Ignacio Peña Sepúlveda
REM Date: June 25, 2025

echo ═══════════════════════════════════════════════════════════════
echo           TEMPO BOOTSTRAP WINDOWS - ZERO C
echo   ╔═════╦═════╦═════╗
echo   ║ 🛡️  ║ ⚖️  ║ ⚡  ║    100%% Assembly
echo   ║  C  ║  E  ║  G  ║
echo   ╚═════╩═════╩═════╝
echo ═══════════════════════════════════════════════════════════════
echo.

REM Verificar NASM
where nasm >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: NASM no encontrado!
    echo Descarga desde: https://www.nasm.us/
    pause
    exit /b 1
)

REM Ensamblar
echo [1/3] Ensamblando bootstrap.asm...
nasm -f win64 bootstrap.asm -o bootstrap.obj

REM Enlazar con kernel32.dll (API de Windows, no libc!)
echo [2/3] Enlazando con Windows API...
link bootstrap.obj /subsystem:console /entry:main kernel32.lib /out:tempo-bootstrap.exe

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Necesitas Visual Studio Build Tools o MinGW
    echo.
    echo Alternativa con GoLink (sin Visual Studio):
    echo   1. Descarga GoLink: http://godevtool.com/
    echo   2. golink /console /entry main bootstrap.obj kernel32.dll
    pause
    exit /b 1
)

REM Compilar stage1
echo [3/3] Compilando stage1.tempo...
tempo-bootstrap.exe ..\stage1.tempo

echo.
echo ✅ ¡Bootstrap Windows completado sin C!
echo.
echo Archivos generados:
echo   - tempo-bootstrap.exe (Bootstrap en assembly)
echo   - stage1.exe (Compilador Tempo)
echo.
echo [T∞] Cero C, puro Tempo
pause