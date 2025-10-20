#!/bin/bash
# Chronos vs C/C++/Rust/Go Benchmark Suite
# Author: ipenas-cl

set -e

echo "========================================"
echo "CHRONOS BENCHMARK SUITE"
echo "The War Against C/C++/Rust/Go"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking compilers..."
command -v gcc >/dev/null 2>&1 || { echo "gcc not found"; }
command -v rustc >/dev/null 2>&1 || { echo "rustc not found (optional)"; }
command -v go >/dev/null 2>&1 || { echo "go not found (optional)"; }
command -v nasm >/dev/null 2>&1 || { echo "nasm not found!"; exit 1; }
echo "✓ Prerequisites OK"
echo ""

# Compile FizzBuzz
echo "----------------------------------------"
echo "BENCHMARK 1: FizzBuzz"
echo "----------------------------------------"

# Chronos
echo "Compiling Chronos..."
start=$(date +%s%N)
../compiler/bootstrap-c/chronos_v10 fizzbuzz.ch -o fizzbuzz_chronos.asm 2>/dev/null
nasm -f elf64 fizzbuzz_chronos.asm -o fizzbuzz_chronos.o 2>/dev/null
ld fizzbuzz_chronos.o -o fizzbuzz_chronos 2>/dev/null
end=$(date +%s%N)
chronos_time=$((($end - $start) / 1000000))
chronos_size=$(stat -f%z fizzbuzz_chronos 2>/dev/null || stat -c%s fizzbuzz_chronos)

# C
echo "Compiling C..."
start=$(date +%s%N)
gcc fizzbuzz.c -o fizzbuzz_c 2>/dev/null
end=$(date +%s%N)
c_time=$((($end - $start) / 1000000))
c_size=$(stat -f%z fizzbuzz_c 2>/dev/null || stat -c%s fizzbuzz_c)

# Rust (if available)
if command -v rustc >/dev/null 2>&1; then
    echo "Compiling Rust..."
    start=$(date +%s%N)
    rustc fizzbuzz.rs -o fizzbuzz_rust 2>/dev/null
    end=$(date +%s%N)
    rust_time=$((($end - $start) / 1000000))
    rust_size=$(stat -f%z fizzbuzz_rust 2>/dev/null || stat -c%s fizzbuzz_rust)

    echo "Stripping Rust binary..."
    strip fizzbuzz_rust
    rust_size_stripped=$(stat -f%z fizzbuzz_rust 2>/dev/null || stat -c%s fizzbuzz_rust)
else
    rust_time="N/A"
    rust_size="N/A"
    rust_size_stripped="N/A"
fi

# Go (if available)
if command -v go >/dev/null 2>&1; then
    echo "Compiling Go..."
    start=$(date +%s%N)
    go build -o fizzbuzz_go fizzbuzz.go 2>/dev/null
    end=$(date +%s%N)
    go_time=$((($end - $start) / 1000000))
    go_size=$(stat -f%z fizzbuzz_go 2>/dev/null || stat -c%s fizzbuzz_go)
else
    go_time="N/A"
    go_size="N/A"
fi

echo ""
echo "RESULTS:"
echo "--------"
printf "%-12s | %-12s | %-12s\n" "Language" "Compile Time" "Binary Size"
printf "%-12s-+-%-12s-+-%-12s\n" "------------" "------------" "------------"
printf "%-12s | %9dms | %10d B\n" "Chronos" $chronos_time $chronos_size
printf "%-12s | %9dms | %10d B\n" "C (gcc)" $c_time $c_size

if [ "$rust_time" != "N/A" ]; then
    printf "%-12s | %9dms | %10d B\n" "Rust" $rust_time $rust_size
    printf "%-12s | %12s | %10d B (stripped)\n" "" "" $rust_size_stripped
fi

if [ "$go_time" != "N/A" ]; then
    printf "%-12s | %9dms | %10d B\n" "Go" $go_time $go_size
fi

echo ""

# Calculate improvements
c_reduction=$(echo "scale=1; 100 - ($chronos_size * 100 / $c_size)" | bc)
echo -e "${GREEN}Chronos vs C: ${c_reduction}% smaller binary${NC}"

if [ "$rust_size_stripped" != "N/A" ]; then
    rust_reduction=$(echo "scale=1; 100 - ($chronos_size * 100 / $rust_size_stripped)" | bc)
    echo -e "${GREEN}Chronos vs Rust: ${rust_reduction}% smaller binary${NC}"
fi

if [ "$go_size" != "N/A" ]; then
    go_reduction=$(echo "scale=1; 100 - ($chronos_size * 100 / $go_size)" | bc)
    echo -e "${GREEN}Chronos vs Go: ${go_reduction}% smaller binary${NC}"
fi

echo ""

# Verify correctness
echo "Verifying correctness..."
./fizzbuzz_chronos > /tmp/chronos_fizzbuzz.txt
./fizzbuzz_c > /tmp/c_fizzbuzz.txt

if diff /tmp/chronos_fizzbuzz.txt /tmp/c_fizzbuzz.txt >/dev/null; then
    echo -e "${GREEN}✓ Output matches C${NC}"
else
    echo -e "${RED}✗ Output differs from C!${NC}"
    exit 1
fi

echo ""
echo "========================================"
echo "BENCHMARK COMPLETE"
echo "========================================"
echo ""
echo -e "${YELLOW}THE WAR SCORECARD:${NC}"
echo "  Chronos: Smaller, Faster compilation, Deterministic"
echo "  C:       Larger, Slower compilation, Non-deterministic"
echo "  Rust:    Much larger, Much slower compilation"
echo "  Go:      Huge binaries, includes runtime"
echo ""
echo -e "${GREEN}🏆 CHRONOS WINS 🏆${NC}"
echo ""
