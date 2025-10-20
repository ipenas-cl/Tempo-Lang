; CHRONOS v0.1 - Deterministic Systems Language

section .text
    global _start

_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall

main:
    mov rax, 42
    ret
