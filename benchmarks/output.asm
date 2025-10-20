; CHRONOS v0.5 - Stdlib Essentials

section .data
str_0: db 70, 105, 122, 122, 66, 117, 122, 122
str_1: db 70, 105, 122, 122
str_2: db 66, 117, 122, 122
str_3: db 

section .text
    global _start

_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall

__print_int:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov rbx, rax
    test rbx, rbx
    jns .positive
    neg rbx
    push rbx
    mov byte [rbp-1], 45
    lea rsi, [rbp-1]
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    syscall
    pop rbx
.positive:
    lea rdi, [rbp-32]
    mov rax, rbx
    mov rcx, 10
.loop:
    xor rdx, rdx
    div rcx
    add dl, 48
    mov [rdi], dl
    inc rdi
    test rax, rax
    jnz .loop
    mov r8, rdi
    dec rdi
.print_loop:
    lea rax, [rbp-32]
    cmp rdi, rax
    jl .done
    push rdi
    mov rsi, rdi
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    syscall
    pop rdi
    dec rdi
    jmp .print_loop
.done:
    leave
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov rax, 1
    mov [rbp-8], rax
.L0:
    mov rax, [rbp-8]
    push rax
    mov rax, 100
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setle al
    movzx rax, al
    test rax, rax
    jz .L1
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    xor rdx, rdx
    idiv rbx
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    xor rdx, rdx
    idiv rbx
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov [rbp-24], rax
    mov rax, [rbp-16]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L2
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L4
    mov rax, str_0
    mov rbx, 8
    mov rsi, rax
    mov rdx, rbx
    mov rdi, 1
    mov rax, 1
    syscall
    mov byte [rbp-32], 10
    lea rsi, [rbp-32]
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    syscall
    jmp .L5
.L4:
    mov rax, str_1
    mov rbx, 4
    mov rsi, rax
    mov rdx, rbx
    mov rdi, 1
    mov rax, 1
    syscall
    mov byte [rbp-32], 10
    lea rsi, [rbp-32]
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    syscall
.L5:
    jmp .L3
.L2:
    mov rax, [rbp-24]
    push rax
    mov rax, 0
    mov rbx, rax
    pop rax
    cmp rax, rbx
    sete al
    movzx rax, al
    test rax, rax
    jz .L6
    mov rax, str_2
    mov rbx, 4
    mov rsi, rax
    mov rdx, rbx
    mov rdi, 1
    mov rax, 1
    syscall
    mov byte [rbp-32], 10
    lea rsi, [rbp-32]
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    syscall
    jmp .L7
.L6:
    mov rax, [rbp-8]
    call __print_int
    mov rax, str_3
    mov rbx, 0
    mov rsi, rax
    mov rdx, rbx
    mov rdi, 1
    mov rax, 1
    syscall
    mov byte [rbp-32], 10
    lea rsi, [rbp-32]
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    syscall
.L7:
.L3:
    mov rax, [rbp-8]
    push rax
    mov rax, 1
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-8], rax
    jmp .L0
.L1:
    mov rax, 0
    leave
    ret
    xor rax, rax
    leave
    ret
