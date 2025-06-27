#!/bin/bash
# Build all Tempo monitoring tools

set -e

echo "🔨 Building Tempo Monitoring Tools..."

# Build monitor
echo "Building tempo-monitor..."
nasm -f macho64 tempo-monitor.asm -o tempo-monitor.o
ld -o tempo-monitor tempo-monitor.o
echo "✅ tempo-monitor built"

# Build debugger
echo "Building tempo-debugger..."
nasm -f macho64 tempo-debugger.asm -o tempo-debugger.o
ld -o tempo-debugger tempo-debugger.o
echo "✅ tempo-debugger built"

# Build alert system
echo "Building tempo-alert..."
nasm -f macho64 tempo-alert.asm -o tempo-alert.o
ld -o tempo-alert tempo-alert.o
echo "✅ tempo-alert built"

# Build log analyzer
echo "Building tempo-logs..."
nasm -f macho64 tempo-logs.asm -o tempo-logs.o
ld -o tempo-logs tempo-logs.o
echo "✅ tempo-logs built"

# Build profiler
echo "Building tempo-profiler..."
nasm -f macho64 tempo-profiler.asm -o tempo-profiler.o
ld -o tempo-profiler tempo-profiler.o
echo "✅ tempo-profiler built"

echo ""
echo "🎉 All monitoring tools built successfully!"
echo ""
echo "Available commands:"
echo "  tempo monitor         - Launch observability dashboard"
echo "  tempo debug <app>     - Debug running application"
echo "  tempo profile <app>   - Generate performance profile for PGO"
echo "  tempo alert <msg>     - Send intelligent alert to SRE"
echo "  tempo logs <app>      - Analyze application logs"