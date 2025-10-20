; Helper: Convert integer in rax to string and print
; Used by print_int() builtin
print_int_impl:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Handle negative
    mov rbx, rax
    test rbx, rbx
    jns .positive
    neg rbx
    push rbx
    mov rax, 45  ; '-'
    mov [rbp-1], al
    mov rsi, rbp
    sub rsi, 1
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    syscall
    pop rbx
    
.positive:
    ; Convert to string (reverse order)
    lea rdi, [rbp-32]
    mov rax, rbx
    mov rcx, 10
    
.loop:
    xor rdx, rdx
    div rcx
    add dl, 48  ; '0'
    mov [rdi], dl
    inc rdi
    test rax, rax
    jnz .loop
    
    ; Print in correct order
    mov rsi, rdi
    dec rsi
.print_loop:
    cmp rsi, rbp
    jl .done
    sub rsi, 32
    
    push rsi
    mov rdi, 1
    mov rdx, 1
    mov rax, 1
    syscall
    pop rsi
    dec rsi
    jmp .print_loop
    
.done:
    leave
    ret
