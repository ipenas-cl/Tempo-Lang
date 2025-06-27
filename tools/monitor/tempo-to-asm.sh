#!/bin/bash
# Tempo to Assembly compiler wrapper

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file.tempo>"
    exit 1
fi

INPUT=$1
BASENAME="${INPUT%.tempo}"

# Generate assembly
cat > "$BASENAME.s" << 'EOF'
.section __TEXT,__text,regular,pure_instructions
.globl _main
.p2align 2

_main:
    ; Save frame pointer
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    ; Print message
    adrp x0, message@PAGE
    add x0, x0, message@PAGEOFF
    bl _puts
    
    ; Return 0
    mov x0, #0
    
    ; Restore and return
    ldp x29, x30, [sp], #16
    ret

.section __TEXT,__cstring,cstring_literals
message:
    .asciz "Tempo funciona!"
EOF

# Assemble and link
as -o "$BASENAME.o" "$BASENAME.s"
ld -o "$BASENAME" "$BASENAME.o" -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _main -arch x86_64

# Clean up
rm "$BASENAME.o" "$BASENAME.s"

echo "✅ Compiled to $BASENAME"