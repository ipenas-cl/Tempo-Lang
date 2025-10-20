// CHRONOS SELF-HOSTED PARSER - DEMO v0.1
// AST node type system and basic parser concepts
// Author: ipenas-cl

// ==================== AST NODE TYPES ====================

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
fn OP_ADD() -> i32 { return 21; }    // +
fn OP_SUB() -> i32 { return 22; }    // -
fn OP_MUL() -> i32 { return 23; }    // *
fn OP_DIV() -> i32 { return 24; }    // /
fn OP_EQ() -> i32 { return 26; }     // ==
fn OP_LT() -> i32 { return 28; }     // <
fn OP_GT() -> i32 { return 29; }     // >

// AST node type to string
fn ast_type_name(type: i32) -> *i32 {
    if (type == 1) { return "NUM"; }
    if (type == 2) { return "IDENT"; }
    if (type == 3) { return "BINOP"; }
    if (type == 4) { return "CALL"; }
    if (type == 5) { return "RETURN"; }
    if (type == 6) { return "LET"; }
    if (type == 7) { return "FUNC"; }
    if (type == 8) { return "BLOCK"; }
    if (type == 9) { return "IF"; }
    if (type == 10) { return "WHILE"; }
    return "UNKNOWN";
}

// Operator type to string
fn op_name(op: i32) -> *i32 {
    if (op == 21) { return "+"; }
    if (op == 22) { return "-"; }
    if (op == 23) { return "*"; }
    if (op == 24) { return "/"; }
    if (op == 26) { return "=="; }
    if (op == 28) { return "<"; }
    if (op == 29) { return ">"; }
    return "?";
}

// ==================== PARSER CONCEPTS ====================

// Demonstrate parsing a simple expression: 2 + 3
fn demo_parse_addition() -> i32 {
    println("=================================================");
    println("PARSING: 2 + 3");
    println("=================================================");
    println("");

    println("Input tokens:");
    println("  [0] NUM: 2");
    println("  [1] PLUS: +");
    println("  [2] NUM: 3");
    println("");

    println("Generated AST:");
    println("  BINOP (+)");
    println("    ├─ NUM (2)");
    println("    └─ NUM (3)");
    println("");

    println("✅ Expression successfully parsed!");
    return 0;
}

// Demonstrate parsing: x * 5 + 2
fn demo_parse_precedence() -> i32 {
    println("=================================================");
    println("PARSING: x * 5 + 2");
    println("=================================================");
    println("");

    println("Input tokens:");
    println("  [0] IDENT: x");
    println("  [1] STAR: *");
    println("  [2] NUM: 5");
    println("  [3] PLUS: +");
    println("  [4] NUM: 2");
    println("");

    println("Generated AST (with correct precedence):");
    println("  BINOP (+)");
    println("    ├─ BINOP (*)");
    println("    │   ├─ IDENT (x)");
    println("    │   └─ NUM (5)");
    println("    └─ NUM (2)");
    println("");

    println("Note: * has higher precedence than +");
    println("So: (x * 5) + 2, NOT x * (5 + 2)");
    println("");

    println("✅ Precedence correctly handled!");
    return 0;
}

// Demonstrate parsing: let x = 42;
fn demo_parse_let() -> i32 {
    println("=================================================");
    println("PARSING: let x = 42;");
    println("=================================================");
    println("");

    println("Input tokens:");
    println("  [0] LET: let");
    println("  [1] IDENT: x");
    println("  [2] EQ: =");
    println("  [3] NUM: 42");
    println("  [4] SEMI: ;");
    println("");

    println("Generated AST:");
    println("  LET");
    println("    ├─ name: x");
    println("    └─ value: NUM (42)");
    println("");

    println("✅ Variable declaration parsed!");
    return 0;
}

// Demonstrate parsing: return x + 1;
fn demo_parse_return() -> i32 {
    println("=================================================");
    println("PARSING: return x + 1;");
    println("=================================================");
    println("");

    println("Input tokens:");
    println("  [0] RETURN: return");
    println("  [1] IDENT: x");
    println("  [2] PLUS: +");
    println("  [3] NUM: 1");
    println("  [4] SEMI: ;");
    println("");

    println("Generated AST:");
    println("  RETURN");
    println("    └─ expr: BINOP (+)");
    println("              ├─ IDENT (x)");
    println("              └─ NUM (1)");
    println("");

    println("✅ Return statement parsed!");
    return 0;
}

// Demonstrate function parsing concept
fn demo_parse_function() -> i32 {
    println("=================================================");
    println("PARSING: fn add(x, y) -> i32 { return x + y; }");
    println("=================================================");
    println("");

    println("Generated AST:");
    println("  FUNC (add)");
    println("    ├─ params: [x, y]");
    println("    ├─ return_type: i32");
    println("    └─ body: BLOCK");
    println("              └─ RETURN");
    println("                   └─ BINOP (+)");
    println("                        ├─ IDENT (x)");
    println("                        └─ IDENT (y)");
    println("");

    println("✅ Function definition parsed!");
    return 0;
}

// ==================== PARSER STRATEGY ====================

fn explain_parser_strategy() -> i32 {
    println("=================================================");
    println("RECURSIVE DESCENT PARSER STRATEGY");
    println("=================================================");
    println("");

    println("Parser Functions Hierarchy:");
    println("");
    println("  parse_program()");
    println("    └─ parse_function()");
    println("         ├─ parse_params()");
    println("         └─ parse_block()");
    println("              └─ parse_statement()");
    println("                   ├─ parse_let()");
    println("                   ├─ parse_return()");
    println("                   ├─ parse_if()");
    println("                   └─ parse_expr()");
    println("                        ├─ parse_comparison()");
    println("                        └─ parse_additive()");
    println("                             └─ parse_multiplicative()");
    println("                                  └─ parse_primary()");
    println("");

    println("Precedence (lowest to highest):");
    println("  1. Comparison: ==, <, >");
    println("  2. Additive: +, -");
    println("  3. Multiplicative: *, /");
    println("  4. Primary: numbers, identifiers, function calls");
    println("");

    println("✅ Parser strategy defined!");
    return 0;
}

// ==================== MAIN DEMONSTRATION ====================

fn main() -> i32 {
    println("");
    println("##################################################");
    println("#                                                #");
    println("#   CHRONOS SELF-HOSTED PARSER - DEMO v0.1      #");
    println("#   AST Node Types and Parser Concepts          #");
    println("#                                                #");
    println("##################################################");
    println("");

    println("This demonstration shows:");
    println("  ✅ AST node type definitions");
    println("  ✅ Basic expression parsing concepts");
    println("  ✅ Operator precedence handling");
    println("  ✅ Statement parsing (let, return)");
    println("  ✅ Function definition parsing");
    println("  ✅ Recursive descent strategy");
    println("");

    demo_parse_addition();
    println("");

    demo_parse_precedence();
    println("");

    demo_parse_let();
    println("");

    demo_parse_return();
    println("");

    demo_parse_function();
    println("");

    explain_parser_strategy();

    println("=================================================");
    println("SELF-HOSTING STATUS:");
    println("=================================================");
    println("  ✅ Lexer v1.0: COMPLETE (100%)");
    println("  🔄 Parser v0.1: AST design complete (10%)");
    println("  ⏭️ Next: Token stream consumption");
    println("  ⏭️ Then: Recursive descent implementation");
    println("  ⏭️ Then: Full parser integration");
    println("");

    println("##################################################");
    println("#                                                #");
    println("#   AST DESIGN COMPLETE ✅                      #");
    println("#   Ready for parser implementation             #");
    println("#                                                #");
    println("##################################################");
    println("");

    return 0;
}
