#!/bin/bash

# ===========================================================================
# BUILD SCRIPT PARA TEMPO BOOTSTRAP EN MACOS
# ===========================================================================
# Compila el bootstrap de Tempo en macOS/Darwin
# Author: Ignacio Peña Sepúlveda
# Date: June 26, 2025
# ===========================================================================

set -e  # Salir si hay errores

echo "╔═════╦═════╦═════╗"
echo "║ 🛡️  ║ ⚖️  ║ ⚡  ║  TEMPO BUILD - macOS"
echo "║  C  ║  E  ║  G  ║"
echo "╚═════╩═════╩═════╝"
echo ""

# Verificar que estamos en macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: Este script es solo para macOS"
    exit 1
fi

# Verificar NASM
if ! command -v nasm &> /dev/null; then
    echo "Error: NASM no está instalado"
    echo "Instala con: brew install nasm"
    exit 1
fi

echo "🔧 Compilando bootstrap.asm..."

# Compilar con NASM para formato Mach-O 64-bit
# -I .. para incluir syscalls.inc del directorio padre
nasm -f macho64 -I .. bootstrap.asm -o bootstrap.o

echo "🔗 Enlazando..."

# Enlazar con ld de macOS
# -e _start: punto de entrada
# -static: enlace estático
# -pagezero_size: tamaño de __PAGEZERO
# -no_pie: desactivar PIE para simplificar
ld -e _start \
   -static \
   -pagezero_size 0x1000 \
   -no_pie \
   -o tempo-bootstrap \
   bootstrap.o

# Limpiar archivos objeto
rm bootstrap.o

echo "✅ tempo-bootstrap compilado!"
echo ""

# Verificar el binario
echo "📊 Información del binario:"
file tempo-bootstrap
echo ""

echo "🎯 Dependencias:"
otool -L tempo-bootstrap
echo ""

echo "[T∞] ¡Bootstrap de Tempo listo para macOS!"
echo "Ejecuta con: ./tempo-bootstrap <archivo.tempo>"