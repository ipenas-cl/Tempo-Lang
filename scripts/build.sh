#!/bin/bash
# ===========================================================================
# TEMPO BUILD SYSTEM
# ===========================================================================
# Professional build system for Tempo programming language
# Copyright (c) 2025 Ignacio Peña Sepúlveda
# ===========================================================================

set -e

echo "╔═════╦═════╦═════╗"
echo "║ 🛡️  ║ ⚖️  ║ ⚡  ║  Tempo Build System"
echo "║  C  ║  E  ║  G  ║"
echo "╚═════╩═════╩═════╝"
echo ""

# Detect platform
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
    echo "🐧 Building for Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    echo "🍎 Building for macOS"
else
    echo "❌ Unsupported platform: $OSTYPE"
    echo "Supported platforms: Linux, macOS"
    exit 1
fi

# Check required tools
echo ""
echo "Checking build requirements..."

if ! command -v nasm &> /dev/null; then
    echo "❌ NASM not found. Please install:"
    if [[ "$PLATFORM" == "linux" ]]; then
        echo "   sudo apt-get install nasm"
    else
        echo "   brew install nasm"
    fi
    exit 1
fi
echo "✅ NASM found"

# Create bin directory if it doesn't exist
mkdir -p bin

# Build the compiler
echo ""
echo "🔨 Building Tempo compiler..."
cd "internal/compiler/$PLATFORM"

if ./build.sh; then
    echo "✅ Compiler built successfully"
else
    echo "❌ Compiler build failed"
    exit 1
fi

# Copy compiler to bin directory
cd ../../..
cp "internal/compiler/$PLATFORM/tempo-bootstrap" "bin/tempo-compiler"

echo ""
echo "🎉 Build complete!"
echo ""
echo "Next steps:"
echo "  bin/tempo hello.ch    # Compile the example"
echo "  ./stage1                 # Run your program"
echo ""
echo "Use 'bin/tempo --help' for more options"