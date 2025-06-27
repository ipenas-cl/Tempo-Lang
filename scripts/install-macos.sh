#!/bin/bash
# Tempo Installation Script for macOS v0.0.1

set -e

echo "╔═════╦═════╦═════╗"
echo "║ 🛡️  ║ ⚖️  ║ ⚡  ║  TEMPO INSTALLER macOS"
echo "║  C  ║  E  ║  G  ║"
echo "╚═════╩═════╩═════╝"
echo ""
echo "Instalando Tempo v0.0.1..."
echo ""

# Detect if we have write access to /usr/local/bin
if [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
    echo "📍 Instalando en: /usr/local/bin"
else
    echo "⚠️  Necesitas permisos de administrador para instalar en /usr/local/bin"
    echo ""
    echo "Ejecuta:"
    echo "  sudo ./install-macos.sh"
    echo ""
    echo "O instala en tu directorio personal:"
    echo "  mkdir -p ~/bin"
    echo "  cp bin/tempo ~/bin/"
    echo "  export PATH=\"\$HOME/bin:\$PATH\""
    exit 1
fi

# Copy tempo wrapper
echo "📦 Instalando tempo..."
cp bin/tempo "$INSTALL_DIR/tempo"
chmod +x "$INSTALL_DIR/tempo"

# Create tempo home directory
TEMPO_HOME="/usr/local/share/tempo"
mkdir -p "$TEMPO_HOME"

# Copy compiler files
echo "📦 Copiando compiladores..."
cp -r internal "$TEMPO_HOME/"

# Set permissions
chmod +x "$TEMPO_HOME/internal/compiler/macos/tempo-compiler" 2>/dev/null || true
chmod +x "$TEMPO_HOME/internal/compiler/linux/tempo-bootstrap" 2>/dev/null || true

# Remove quarantine from macOS binaries
xattr -cr "$TEMPO_HOME/internal/compiler/macos/tempo-compiler" 2>/dev/null || true

# Update tempo wrapper to use installed location
cat > "$INSTALL_DIR/tempo" << 'EOF'
#!/bin/bash
# Tempo Compiler
# Copyright (c) 2025 Ignacio Peña Sepúlveda

set -e

TEMPO_HOME="/usr/local/share/tempo"

# Detect OS and select compiler
case "$(uname)" in
    Darwin)
        COMPILER="$TEMPO_HOME/internal/compiler/macos/tempo-compiler"
        ;;
    Linux)
        COMPILER="$TEMPO_HOME/internal/compiler/linux/tempo-bootstrap"
        ;;
    *)
        echo "❌ Sistema operativo no soportado"
        exit 1
        ;;
esac

# Check if compiler exists
if [ ! -f "$COMPILER" ]; then
    echo "❌ Tempo compiler not found at: $COMPILER"
    exit 1
fi

# Show help if no arguments
if [ $# -eq 0 ]; then
    echo "Tempo Programming Language v0.0.1"
    echo ""
    echo "Usage:"
    echo "  tempo <file.tempo>    Compile a Tempo program"
    echo "  tempo --version       Show version"
    echo "  tempo --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  tempo hello.tempo     # Compiles to 'stage1'"
    echo "  ./stage1              # Run the compiled program"
    echo ""
    exit 0
fi

# Handle flags
case "$1" in
    --help|-h)
        $0
        exit 0
        ;;
    --version|-v)
        echo "Tempo 0.0.1 - Deterministic Programming Language"
        echo "Built with zero C dependencies"
        exit 0
        ;;
    -*)
        echo "Unknown option: $1"
        echo "Use 'tempo --help' for usage information"
        exit 1
        ;;
esac

# Check if input file exists
if [ ! -f "$1" ]; then
    echo "❌ File not found: $1"
    exit 1
fi

# Check if it's a .tempo file
if [[ "$1" != *.tempo ]]; then
    echo "❌ File must have .tempo extension"
    exit 1
fi

# Change to the directory where the source file is located
SOURCE_DIR="$(dirname "$1")"
SOURCE_FILE="$(basename "$1")"

if [ "$SOURCE_DIR" != "." ]; then
    cd "$SOURCE_DIR"
fi

# Compile
echo "🔥 Compiling $1..."
"$COMPILER" "$SOURCE_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Compilation successful!"
    echo "   Run with: ./stage1"
else
    echo "❌ Compilation failed"
    exit 1
fi
EOF

chmod +x "$INSTALL_DIR/tempo"

echo ""
echo "✅ ¡Tempo v0.0.1 instalado exitosamente!"
echo ""
echo "Prueba con:"
echo "  tempo --version"
echo "  tempo hello.tempo"
echo ""