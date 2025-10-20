// CHRONOS SELF-HOSTED PARSER v0.1
// AST node types and basic concepts
// Author: ipenas-cl

// ==================== AST NODE TYPES ====================

fn AST_NUM() -> i32 { return 1; }
fn AST_IDENT() -> i32 { return 2; }
fn AST_BINOP() -> i32 { return 3; }
fn AST_CALL() -> i32 { return 4; }
fn AST_RETURN() -> i32 { return 5; }
fn AST_LET() -> i32 { return 6; }
fn AST_FUNC() -> i32 { return 7; }

// Binary operators
fn OP_ADD() -> i32 { return 21; }
fn OP_MUL() -> i32 { return 23; }

// AST type names
fn ast_name(type: i32) -> *i32 {
    if (type == 1) { return "NUM"; }
    if (type == 2) { return "IDENT"; }
    if (type == 3) { return "BINOP"; }
    if (type == 4) { return "CALL"; }
    if (type == 5) { return "RETURN"; }
    if (type == 6) { return "LET"; }
    if (type == 7) { return "FUNC"; }
    return "?";
}

// ==================== DEMONSTRATION ====================

fn demo_ast_types() -> i32 {
    println("AST Node Types:");
    println("");

    print("  AST_NUM = ");
    print_int(AST_NUM());
    println("");

    print("  AST_IDENT = ");
    print_int(AST_IDENT());
    println("");

    print("  AST_BINOP = ");
    print_int(AST_BINOP());
    println("");

    print("  AST_RETURN = ");
    print_int(AST_RETURN());
    println("");

    print("  AST_LET = ");
    print_int(AST_LET());
    println("");

    print("  AST_FUNC = ");
    print_int(AST_FUNC());
    println("");

    return 0;
}

fn demo_simple_expr() -> i32 {
    println("=================================================");
    println("Parsing: 2 + 3");
    println("=================================================");
    println("");

    println("Tokens:");
    println("  [0] NUM: 2");
    println("  [1] PLUS: +");
    println("  [2] NUM: 3");
    println("");

    println("AST:");
    println("  BINOP (+)");
    println("    left: NUM (2)");
    println("    right: NUM (3)");
    println("");

    return 0;
}

fn demo_precedence() -> i32 {
    println("=================================================");
    println("Parsing: x * 5 + 2");
    println("=================================================");
    println("");

    println("Tokens:");
    println("  [0] IDENT: x");
    println("  [1] STAR: *");
    println("  [2] NUM: 5");
    println("  [3] PLUS: +");
    println("  [4] NUM: 2");
    println("");

    println("AST (correct precedence):");
    println("  BINOP (+)");
    println("    left: BINOP (*)");
    println("      left: IDENT (x)");
    println("      right: NUM (5)");
    println("    right: NUM (2)");
    println("");

    println("Result: (x * 5) + 2");
    println("");

    return 0;
}

fn main() -> i32 {
    println("");
    println("=================================================");
    println("CHRONOS SELF-HOSTED PARSER v0.1");
    println("=================================================");
    println("");

    demo_ast_types();
    println("");

    demo_simple_expr();
    demo_precedence();

    println("=================================================");
    println("PARSER CONCEPTS:");
    println("=================================================");
    println("  1. AST node types defined");
    println("  2. Token stream to AST tree");
    println("  3. Operator precedence handling");
    println("  4. Recursive descent strategy");
    println("");

    println("=================================================");
    println("STATUS:");
    println("=================================================");
    println("  Lexer: COMPLETE");
    println("  Parser: AST design complete (10%)");
    println("  Next: Token consumption implementation");
    println("");

    return 0;
}
