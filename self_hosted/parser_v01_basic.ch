// CHRONOS SELF-HOSTED PARSER v0.1
// AST node type system
// Author: ipenas-cl

// AST node type constants
fn AST_NUM() -> i32 { return 1; }
fn AST_IDENT() -> i32 { return 2; }
fn AST_BINOP() -> i32 { return 3; }
fn AST_CALL() -> i32 { return 4; }
fn AST_RETURN() -> i32 { return 5; }
fn AST_LET() -> i32 { return 6; }
fn AST_FUNC() -> i32 { return 7; }
fn AST_BLOCK() -> i32 { return 8; }
fn AST_IF() -> i32 { return 9; }
fn AST_WHILE() -> i32 { return 10; }

// Binary operator types
fn OP_ADD() -> i32 { return 21; }
fn OP_SUB() -> i32 { return 22; }
fn OP_MUL() -> i32 { return 23; }
fn OP_DIV() -> i32 { return 24; }

fn main() -> i32 {
    println("");
    println("=================================================");
    println("CHRONOS SELF-HOSTED PARSER v0.1");
    println("AST Node Type System");
    println("=================================================");
    println("");

    println("AST Node Types:");
    print("  AST_NUM = ");
    print_int(AST_NUM());
    println("");

    print("  AST_IDENT = ");
    print_int(AST_IDENT());
    println("");

    print("  AST_BINOP = ");
    print_int(AST_BINOP());
    println("");

    print("  AST_CALL = ");
    print_int(AST_CALL());
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

    print("  AST_BLOCK = ");
    print_int(AST_BLOCK());
    println("");

    print("  AST_IF = ");
    print_int(AST_IF());
    println("");

    print("  AST_WHILE = ");
    print_int(AST_WHILE());
    println("");

    println("");
    println("Binary Operators:");
    print("  OP_ADD = ");
    print_int(OP_ADD());
    println("");

    print("  OP_SUB = ");
    print_int(OP_SUB());
    println("");

    print("  OP_MUL = ");
    print_int(OP_MUL());
    println("");

    print("  OP_DIV = ");
    print_int(OP_DIV());
    println("");

    println("");
    println("=================================================");
    println("PARSER EXAMPLE: Parsing '2 + 3'");
    println("=================================================");
    println("");

    println("Input Tokens:");
    println("  [0] NUM: 2");
    println("  [1] PLUS: +");
    println("  [2] NUM: 3");
    println("");

    println("Output AST:");
    println("  BINOP (type=3, op=21)");
    println("    left: NUM (type=1, value=2)");
    println("    right: NUM (type=1, value=3)");
    println("");

    println("=================================================");
    println("PARSER EXAMPLE: Parsing 'x * 5 + 2'");
    println("=================================================");
    println("");

    println("Input Tokens:");
    println("  [0] IDENT: x");
    println("  [1] STAR: *");
    println("  [2] NUM: 5");
    println("  [3] PLUS: +");
    println("  [4] NUM: 2");
    println("");

    println("Output AST (with precedence):");
    println("  BINOP (type=3, op=21)  <- ADD");
    println("    left: BINOP (type=3, op=23)  <- MUL");
    println("      left: IDENT (type=2, name=x)");
    println("      right: NUM (type=1, value=5)");
    println("    right: NUM (type=1, value=2)");
    println("");

    println("Result: (x * 5) + 2  <- correct precedence!");
    println("");

    println("=================================================");
    println("PARSER STRATEGY:");
    println("=================================================");
    println("  1. Recursive descent parsing");
    println("  2. Operator precedence levels:");
    println("     - Comparison: ==, <, >");
    println("     - Additive: +, -");
    println("     - Multiplicative: *, /");
    println("     - Primary: nums, idents, calls");
    println("  3. Token stream consumption");
    println("  4. AST tree construction");
    println("");

    println("=================================================");
    println("STATUS:");
    println("=================================================");
    println("  Lexer: 100% COMPLETE");
    println("  Parser: AST types defined (10%)");
    println("  Next: Token consumption");
    println("");

    return 0;
}
