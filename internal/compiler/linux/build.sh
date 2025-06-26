#!/bin/bash
# Build Tempo Bootstrap para Linux - CERO C
# Author: Ignacio Peña Sepúlveda
# Date: June 25, 2025

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           TEMPO BOOTSTRAP LINUX - ZERO C                      ║"
echo "║  ╔═════╦═════╦═════╗                                         ║"
echo "║  ║ 🛡️  ║ ⚖️  ║ ⚡  ║    100% Assembly                        ║"
echo "║  ║  C  ║  E  ║  G  ║                                         ║"
echo "║  ╚═════╩═════╩═════╝                                         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Verificar NASM
if ! command -v nasm &> /dev/null; then
    echo "ERROR: NASM no encontrado!"
    echo "Instala con: sudo apt-get install nasm"
    exit 1
fi

# Ensamblar
echo "[1/3] Ensamblando bootstrap.asm..."
nasm -f elf64 bootstrap.asm -o bootstrap.o

# Enlazar (sin libc!)
echo "[2/3] Enlazando (sin libc)..."
ld bootstrap.o -o tempo-bootstrap

# Hacer ejecutable
chmod +x tempo-bootstrap

# Compilar stage1
echo "[3/3] Compilando stage1.tempo..."
./tempo-bootstrap ../stage1.tempo

echo ""
echo "✅ ¡Bootstrap Linux completado sin C!"
echo ""
echo "Archivos generados:"
echo "  - tempo-bootstrap (Bootstrap en assembly)"
echo "  - stage1 (Compilador Tempo)"
echo ""
echo "[T∞] Cero C, puro Tempo"