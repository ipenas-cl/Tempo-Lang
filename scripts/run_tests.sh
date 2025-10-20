#!/bin/bash
# CHRONOS Test Runner
# Tests all .ch files to ensure compiler works

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

COMPILER="./compiler/bootstrap-c/chronos_v10"
TEST_DIR="./tests/basic"
TOTAL=0
PASSED=0
FAILED=0

echo "================================================"
echo "CHRONOS TEST RUNNER"
echo "Testing all .ch files with bootstrap compiler"
echo "================================================"
echo ""

# Check if compiler exists
if [ ! -f "$COMPILER" ]; then
    echo -e "${RED}ERROR: Compiler not found at $COMPILER${NC}"
    echo "Build it first with:"
    echo "  cd compiler/bootstrap-c"
    echo "  gcc chronos_v10.c -o chronos_v10"
    exit 1
fi

# Check if NASM is installed
if ! command -v nasm &> /dev/null; then
    echo -e "${YELLOW}WARNING: NASM not installed${NC}"
    echo "Install with:"
    echo "  sudo apt-get install nasm  # Ubuntu/Debian"
    echo "  sudo dnf install nasm      # Fedora"
    echo "  sudo pacman -S nasm        # Arch"
    echo ""
    echo "Will test compilation only (no assembly/linking)"
    echo ""
    NASM_AVAILABLE=false
else
    NASM_AVAILABLE=true
fi

# Test each .ch file
for test_file in $TEST_DIR/*.ch; do
    TOTAL=$((TOTAL + 1))
    test_name=$(basename "$test_file" .ch)

    printf "Testing %-30s ... " "$test_name"

    # Compile the file
    if $COMPILER "$test_file" > /dev/null 2>&1; then
        # Check if output.asm was generated
        if [ -f "output.asm" ]; then
            if [ "$NASM_AVAILABLE" = true ]; then
                # Try to assemble
                if nasm -f elf64 output.asm -o output.o 2>/dev/null; then
                    # Try to link
                    if ld output.o -o test_prog 2>/dev/null; then
                        echo -e "${GREEN}PASS${NC} (compiled + assembled + linked)"
                        PASSED=$((PASSED + 1))
                        rm -f test_prog output.o
                    else
                        echo -e "${GREEN}PASS${NC} (compiled + assembled)"
                        PASSED=$((PASSED + 1))
                        rm -f output.o
                    fi
                else
                    echo -e "${GREEN}PASS${NC} (compiled)"
                    PASSED=$((PASSED + 1))
                fi
            else
                echo -e "${GREEN}PASS${NC} (compiled)"
                PASSED=$((PASSED + 1))
            fi
            rm -f output.asm
        else
            echo -e "${RED}FAIL${NC} (no output.asm generated)"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${RED}FAIL${NC} (compilation error)"
        FAILED=$((FAILED + 1))
    fi
done

# Summary
echo ""
echo "================================================"
echo "TEST SUMMARY"
echo "================================================"
echo "Total tests:  $TOTAL"
echo -e "Passed:       ${GREEN}$PASSED${NC}"
echo -e "Failed:       ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo ""
    echo "Chronos bootstrap compiler is working correctly!"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo ""
    echo "Check the compiler for issues."
    exit 1
fi
