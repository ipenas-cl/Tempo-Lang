#!/bin/bash
# ===========================================================================
# TEMPO BUILD SYSTEM
# ===========================================================================
# Sistema de construcción para el compilador Tempo
# Author: Ignacio Peña Sepúlveda
# Date: June 25, 2025
# ===========================================================================

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                  TEMPO BUILD SYSTEM                           ║"
echo "║  ╔═════╦═════╦═════╗                                         ║"
echo "║  ║ 🛡️  ║ ⚖️  ║ ⚡  ║    Building from Assembly                ║"
echo "║  ║  C  ║  E  ║  G  ║                                         ║"
echo "║  ╚═════╩═════╩═════╝                                         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Detectar plataforma
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
    echo "🐧 Plataforma detectada: Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    echo "🍎 Plataforma detectada: macOS"
else
    echo "❌ Plataforma no soportada: $OSTYPE"
    exit 1
fi

# Verificar herramientas necesarias
echo ""
echo "Verificando herramientas..."

if ! command -v nasm &> /dev/null; then
    echo "❌ NASM no encontrado. Instala con:"
    echo "   Ubuntu/Debian: sudo apt-get install nasm"
    echo "   macOS: brew install nasm"
    exit 1
fi
echo "✓ NASM encontrado"

# Directorio de trabajo
COMPILER_DIR="compiler"
BUILD_DIR="build/$PLATFORM"
STAGES_DIR="$COMPILER_DIR/stages"

# Crear directorios
mkdir -p "$BUILD_DIR"

# PASO 1: Construir bootstrap desde assembly
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "PASO 1: Construyendo bootstrap desde assembly puro..."
echo "═══════════════════════════════════════════════════════════════"

cd "$COMPILER_DIR/$PLATFORM"
echo "Ensamblando bootstrap.asm..."
nasm -f elf64 bootstrap.asm -o bootstrap.o

echo "Enlazando (sin libc)..."
ld bootstrap.o -o tempo-bootstrap

echo "✓ Bootstrap creado: tempo-bootstrap"
cd ../..

# PASO 2: Compilar Stage 0
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "PASO 2: Compilando Stage 0..."
echo "═══════════════════════════════════════════════════════════════"

cd "$STAGES_DIR/stage0"
echo "Ensamblando bootstrap.s..."
nasm -f elf64 bootstrap.s -o bootstrap.o
ld bootstrap.o -o stage0

echo "✓ Stage 0 creado"
cd ../../..

# PASO 3: Compilar Stage 1 con Stage 0
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "PASO 3: Compilando Stage 1 con Stage 0..."
echo "═══════════════════════════════════════════════════════════════"

"$STAGES_DIR/stage0/stage0" "$STAGES_DIR/stage1/compiler.tempo" "$BUILD_DIR/stage1"
echo "✓ Stage 1 creado"

# PASO 4: Compilar Stage 2 con Stage 1
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "PASO 4: Compilando Stage 2 con Stage 1..."
echo "═══════════════════════════════════════════════════════════════"

"$BUILD_DIR/stage1" "$STAGES_DIR/stage2/compiler.tempo" "$BUILD_DIR/stage2"
echo "✓ Stage 2 creado"

# PASO 5: Compilar compilador final con Stage 2
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "PASO 5: Compilando Tempo final con Stage 2..."
echo "═══════════════════════════════════════════════════════════════"

"$BUILD_DIR/stage2" "$COMPILER_DIR/tempo.tempo" "$BUILD_DIR/tempo"
echo "✓ Tempo compilador creado"

# Crear enlace simbólico en la raíz
ln -sf "$BUILD_DIR/tempo" tempo

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ ¡BUILD COMPLETADO!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "El compilador Tempo está listo para usar:"
echo "  ./tempo programa.tempo"
echo ""
echo "Proceso de construcción:"
echo "  1. Assembly (bootstrap.asm) → Bootstrap"
echo "  2. Assembly (stage0) → Stage 0"
echo "  3. Stage 0 → Stage 1"
echo "  4. Stage 1 → Stage 2"
echo "  5. Stage 2 → Tempo"
echo ""
echo "[T∞] 100% Tempo, 0% C"