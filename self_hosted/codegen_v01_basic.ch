// CHRONOS SELF-HOSTED CODEGEN v0.1
// Assembly emission architecture
// Author: ipenas-cl

// ==================== AST NODE TYPES ====================

fn AST_NUM() -> i32 { return 1; }
fn AST_IDENT() -> i32 { return 2; }
fn AST_BINOP() -> i32 { return 3; }
fn AST_RETURN() -> i32 { return 5; }
fn AST_LET() -> i32 { return 6; }
fn AST_FUNC() -> i32 { return 7; }

fn OP_ADD() -> i32 { return 21; }
fn OP_SUB() -> i32 { return 22; }
fn OP_MUL() -> i32 { return 23; }
fn OP_DIV() -> i32 { return 24; }

// ==================== ASSEMBLY EMISSION ====================

// Emit assembly instruction
fn emit_asm(instruction: *i32) -> i32 {
    print("    ");
    println(instruction);
    return 0;
}

// Emit comment
fn emit_comment(comment: *i32) -> i32 {
    print("    ; ");
    println(comment);
    return 0;
}

// Emit label
fn emit_label(label: *i32) -> i32 {
    print(label);
    println(":");
    return 0;
}

// ==================== CODE GENERATION DEMOS ====================

// Generate code for: 42
fn codegen_number_demo() -> i32 {
    println("Input AST: NUM (42)");
    println("");
    println("Generated Assembly:");
    emit_comment("Load immediate value 42");
    emit_asm("mov rax, 42");
    println("");
    return 0;
}

// Generate code for: x
fn codegen_ident_demo() -> i32 {
    println("Input AST: IDENT (x)");
    println("");
    println("Generated Assembly:");
    emit_comment("Load variable 'x' from stack");
    emit_comment("Assume x is at [rbp-8]");
    emit_asm("mov rax, [rbp-8]");
    println("");
    return 0;
}

// Generate code for: 2 + 3
fn codegen_add_demo() -> i32 {
    println("Input AST: BINOP (ADD)");
    println("  left: NUM (2)");
    println("  right: NUM (3)");
    println("");
    println("Generated Assembly:");
    emit_comment("Evaluate left operand");
    emit_asm("mov rax, 2");
    emit_comment("Push left result");
    emit_asm("push rax");
    emit_comment("Evaluate right operand");
    emit_asm("mov rax, 3");
    emit_comment("Pop left into rbx");
    emit_asm("pop rbx");
    emit_comment("Add: rbx + rax -> rax");
    emit_asm("add rax, rbx");
    println("");
    return 0;
}

// Generate code for: x * 5
fn codegen_multiply_demo() -> i32 {
    println("Input AST: BINOP (MUL)");
    println("  left: IDENT (x)");
    println("  right: NUM (5)");
    println("");
    println("Generated Assembly:");
    emit_comment("Evaluate left operand (variable)");
    emit_asm("mov rax, [rbp-8]");
    emit_asm("push rax");
    emit_comment("Evaluate right operand (constant)");
    emit_asm("mov rax, 5");
    emit_asm("pop rbx");
    emit_comment("Multiply: rbx * rax -> rax");
    emit_asm("imul rax, rbx");
    println("");
    return 0;
}

// Generate code for: (2 + 3) * 4
fn codegen_complex_expr_demo() -> i32 {
    println("Input AST: BINOP (MUL)");
    println("  left: BINOP (ADD)");
    println("    left: NUM (2)");
    println("    right: NUM (3)");
    println("  right: NUM (4)");
    println("");
    println("Generated Assembly:");
    emit_comment("Evaluate left: (2 + 3)");
    emit_asm("mov rax, 2");
    emit_asm("push rax");
    emit_asm("mov rax, 3");
    emit_asm("pop rbx");
    emit_asm("add rax, rbx");
    emit_comment("Result of (2+3) in rax, push it");
    emit_asm("push rax");
    emit_comment("Evaluate right: 4");
    emit_asm("mov rax, 4");
    emit_comment("Pop left result");
    emit_asm("pop rbx");
    emit_comment("Multiply: (2+3) * 4");
    emit_asm("imul rax, rbx");
    println("");
    return 0;
}

// ==================== CODEGEN STRATEGY ====================

fn explain_codegen_strategy() -> i32 {
    println("=================================================");
    println("CODE GENERATION STRATEGY");
    println("=================================================");
    println("");

    println("Register Usage:");
    println("  rax - Primary accumulator (expression results)");
    println("  rbx - Temporary for binary operations");
    println("  rbp - Base pointer (stack frame)");
    println("  rsp - Stack pointer");
    println("");

    println("Stack-Based Evaluation:");
    println("  1. Evaluate left operand -> rax");
    println("  2. Push rax to stack");
    println("  3. Evaluate right operand -> rax");
    println("  4. Pop stack to rbx");
    println("  5. Perform operation: rbx OP rax -> rax");
    println("  6. Result in rax");
    println("");

    println("Binary Operations:");
    println("  ADD: add rax, rbx");
    println("  SUB: sub rbx, rax  (then mov rax, rbx)");
    println("  MUL: imul rax, rbx");
    println("  DIV: (more complex, uses rdx)");
    println("");

    println("Variables:");
    println("  - Stored on stack relative to rbp");
    println("  - First variable: [rbp-8]");
    println("  - Second variable: [rbp-16]");
    println("  - Third variable: [rbp-24]");
    println("  - Pattern: [rbp - (index * 8)]");
    println("");

    return 0;
}

// ==================== ASSEMBLY SECTIONS ====================

fn demo_assembly_structure() -> i32 {
    println("=================================================");
    println("ASSEMBLY FILE STRUCTURE");
    println("=================================================");
    println("");

    println("Complete Assembly File:");
    println("");
    println("section .data");
    println("  str_0: db 72, 101, 108, 108, 111, 0  ; \"Hello\"");
    println("");
    println("section .text");
    println("  global _start");
    println("");
    emit_label("_start");
    emit_comment("Entry point");
    emit_asm("call main");
    emit_comment("Exit with return value");
    emit_asm("mov rdi, rax");
    emit_asm("mov rax, 60");
    emit_asm("syscall");
    println("");
    emit_label("main");
    emit_comment("Function prologue");
    emit_asm("push rbp");
    emit_asm("mov rbp, rsp");
    emit_comment("Function body");
    emit_asm("mov rax, 42");
    emit_comment("Function epilogue");
    emit_asm("leave");
    emit_asm("ret");
    println("");

    return 0;
}

// ==================== MAIN ====================

fn main() -> i32 {
    println("");
    println("##################################################");
    println("#                                                #");
    println("#   CHRONOS SELF-HOSTED CODEGEN v0.1           #");
    println("#   Assembly Emission Architecture              #");
    println("#                                                #");
    println("##################################################");
    println("");

    println("Codegen Functions:");
    println("  ✅ emit_asm(instruction)  - Emit assembly");
    println("  ✅ emit_comment(text)     - Emit comment");
    println("  ✅ emit_label(name)       - Emit label");
    println("");

    println("=================================================");
    println("EXAMPLE 1: Generate code for number");
    println("=================================================");
    println("");
    codegen_number_demo();

    println("=================================================");
    println("EXAMPLE 2: Generate code for variable");
    println("=================================================");
    println("");
    codegen_ident_demo();

    println("=================================================");
    println("EXAMPLE 3: Generate code for addition");
    println("=================================================");
    println("");
    codegen_add_demo();

    println("=================================================");
    println("EXAMPLE 4: Generate code for multiplication");
    println("=================================================");
    println("");
    codegen_multiply_demo();

    println("=================================================");
    println("EXAMPLE 5: Complex expression");
    println("=================================================");
    println("");
    codegen_complex_expr_demo();

    explain_codegen_strategy();
    demo_assembly_structure();

    println("=================================================");
    println("STATUS:");
    println("=================================================");
    println("  ✅ Lexer: 100% COMPLETE");
    println("  ✅ Parser: 75% (design complete)");
    println("  🔄 Codegen: 10% (architecture defined)");
    println("  🔄 Next: Expression codegen");
    println("  ⏭️ Then: Statement codegen");
    println("  ⏭️ Then: Function codegen");
    println("");

    println("Codegen Progress: ~10% complete");
    println("");

    println("##################################################");
    println("#                                                #");
    println("#   CODEGEN ARCHITECTURE DEFINED ✅            #");
    println("#   Assembly emission ready!                    #");
    println("#                                                #");
    println("##################################################");
    println("");

    return 0;
}
