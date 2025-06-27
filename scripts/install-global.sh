#!/bin/bash
# Tempo Global Installation Script for macOS
# Installs Tempo system-wide for all users

set -e

echo "🚀 TEMPO GLOBAL INSTALLATION"
echo "============================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run with sudo for global installation"
    echo ""
    echo "Usage:"
    echo "  sudo ./install-global.sh"
    echo ""
    echo "This will install Tempo to:"
    echo "  /usr/local/bin/tempo           # Global command"
    echo "  /usr/local/share/tempo/        # Installation files"
    echo "  /usr/local/share/man/man1/     # Manual pages"
    echo ""
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Installing from: $SCRIPT_DIR"
echo ""

# Create installation directories
echo "1️⃣ Creating installation directories..."
mkdir -p /usr/local/bin
mkdir -p /usr/local/share/tempo
mkdir -p /usr/local/share/man/man1
mkdir -p /usr/local/share/doc/tempo
echo "✅ Directories created"

# Copy main tempo command
echo ""
echo "2️⃣ Installing tempo command..."
cp "$SCRIPT_DIR/../bin/tempo" /usr/local/bin/tempo
chmod +x /usr/local/bin/tempo
echo "✅ Command installed to /usr/local/bin/tempo"

# Copy supporting files with new structure
echo ""
echo "3️⃣ Installing supporting files..."
cp -r "$SCRIPT_DIR/../compiler" /usr/local/share/tempo/
cp -r "$SCRIPT_DIR/../runtime" /usr/local/share/tempo/
cp -r "$SCRIPT_DIR/../stdlib" /usr/local/share/tempo/
cp -r "$SCRIPT_DIR/../tools" /usr/local/share/tempo/
cp -r "$SCRIPT_DIR/../examples" /usr/local/share/tempo/
cp -r "$SCRIPT_DIR/../scripts" /usr/local/share/tempo/
echo "✅ Supporting files installed"

# Ensure monitoring tools are executable
echo ""
echo "4️⃣ Setting permissions for monitoring tools..."
if [ -d "/usr/local/share/tempo/tools/monitor" ]; then
    chmod +x /usr/local/share/tempo/tools/monitor/tempo-*
    echo "✅ Monitoring tools configured"
else
    echo "⚠️ Monitoring tools directory not found"
fi

# Update paths in tempo command
echo ""
echo "5️⃣ Updating paths for global installation..."
sed -i '' 's|ROOT_DIR="$(dirname "$SCRIPT_DIR")"|ROOT_DIR="/usr/local/share/tempo"|g' /usr/local/bin/tempo
echo "✅ Paths updated"

# Install documentation
echo ""
echo "6️⃣ Installing documentation..."
cp "$SCRIPT_DIR/../README.md" /usr/local/share/doc/tempo/
cp "$SCRIPT_DIR/../LOGRO.md" /usr/local/share/doc/tempo/
cp "$SCRIPT_DIR/../LICENSE" /usr/local/share/doc/tempo/
if [ -f "$SCRIPT_DIR/../STRUCTURE.md" ]; then
    cp "$SCRIPT_DIR/../STRUCTURE.md" /usr/local/share/doc/tempo/
fi
echo "✅ Documentation installed"

# Create man page
echo ""
echo "7️⃣ Creating manual page..."
cat > /usr/local/share/man/man1/tempo.1 << 'EOF'
.TH TEMPO 1 "2025-06-27" "Tempo 0.0.1" "User Commands"
.SH NAME
tempo \- Deterministic programming language compiler for AtomicOS
.SH SYNOPSIS
.B tempo
[\fIOPTION\fR]... [\fIFILE\fR]...
.SH DESCRIPTION
Tempo is a deterministic programming language designed for real-time systems, embedded programming, and AtomicOS development. It provides WCET (Worst-Case Execution Time) guarantees, zero C dependencies, and extreme performance optimizations.

.SH OPTIONS
.TP
.B \-\-help, \-h
Display help information and usage examples
.TP
.B \-\-version, \-v
Display version information
.TP
.B monitor
Launch Tempo observability dashboard (htop-style for Tempo apps)
.TP
.B debug \fIAPP\fR
Debug a running Tempo application with advanced WCET analysis
.TP
.B logs \fIAPP\fR
Analyze logs for a Tempo application with intelligent insights
.TP
.B profile \fIAPP\fR
Generate performance profile for Profile-Guided Optimization (PGO)
.TP
.B alert \fIMESSAGE\fR
Send intelligent alert to SRE team with system context

.SH EXAMPLES
.TP
.B tempo hello.tempo
Compile hello.tempo to tempo.app executable
.TP
.B tempo monitor
Launch system monitoring for all Tempo applications
.TP
.B tempo debug payment-service.app
Debug a running payment service with real-time analysis
.TP
.B tempo profile myapp.app
Generate PGO data for ultra-high performance optimization
.TP
.B tempo alert "WCET violation detected"
Send contextual alert to SRE team

.SH LANGUAGE FEATURES
Tempo supports advanced real-time programming features:
.IP \[bu] 2
WCET annotations: @wcet(1000) for deterministic timing
.IP \[bu] 2
Inline assembly: @asm("rdtsc") for hardware control
.IP \[bu] 2
Atomic operations: @atomic {} for lock-free concurrency
.IP \[bu] 2
Memory layout control: @section(), @align(), @address()
.IP \[bu] 2
SIMD vectorization: @simd, @vectorize(16)
.IP \[bu] 2
Zero-copy operations: @zero_copy, @no_alloc
.IP \[bu] 2
Cache optimization: @cache_aligned, @prefetch_hint

.SH FILES
.TP
.I /usr/local/bin/tempo
Main Tempo compiler command
.TP
.I /usr/local/share/tempo/
Tempo installation directory
.TP
.I /usr/local/share/tempo/examples/
Example Tempo programs
.TP
.I /usr/local/share/doc/tempo/
Documentation and guides

.SH AUTHOR
Created by the Tempo development team. Built with zero C dependencies using 100% assembly.

.SH SEE ALSO
.BR gcc (1),
.BR clang (1),
.BR rust (1)

For more information, visit the Tempo documentation at /usr/local/share/doc/tempo/
EOF

echo "✅ Manual page created"

# Test installation
echo ""
echo "8️⃣ Testing global installation..."
if tempo --version >/dev/null 2>&1; then
    echo "✅ Global installation test successful"
else
    echo "⚠️ Installation test failed - may need shell restart"
fi

# Set proper permissions
echo ""
echo "9️⃣ Setting permissions..."
chown -R root:wheel /usr/local/share/tempo
chmod -R 755 /usr/local/share/tempo
chmod 755 /usr/local/bin/tempo
echo "✅ Permissions set"

# Installation complete
echo ""
echo "🎉 TEMPO GLOBAL INSTALLATION COMPLETE!"
echo "======================================"
echo ""
echo "✅ Tempo is now installed globally and available from anywhere:"
echo "   tempo --help              # Show help"
echo "   tempo --version           # Show version"  
echo "   tempo myprogram.tempo     # Compile program"
echo "   tempo monitor             # Launch monitoring"
echo ""
echo "📁 Installation locations:"
echo "   Command:       /usr/local/bin/tempo"
echo "   Files:         /usr/local/share/tempo/"
echo "   Documentation: /usr/local/share/doc/tempo/"
echo "   Manual:        man tempo"
echo ""
echo "🎯 Test your installation:"
echo "   echo 'fn main() -> i32 { return 0; }' > test.tempo"
echo "   tempo test.tempo"
echo "   ./tempo.app"
echo ""
echo "🏆 AtomicOS Ecosystem Ready Globally!"
echo "   Determinismo ✅ Seguridad ✅ Estabilidad ✅ Performance ✅"
echo ""
echo "💡 You may need to restart your terminal or run 'hash -r'"
echo "   to refresh the command cache."