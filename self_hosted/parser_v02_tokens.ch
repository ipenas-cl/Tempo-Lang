// CHRONOS SELF-HOSTED PARSER v0.2
// Token consumption and parser state
// Author: ipenas-cl

// ==================== TOKEN TYPES (from Lexer) ====================

fn T_EOF() -> i32 { return 0; }
fn T_IDENT() -> i32 { return 1; }
fn T_NUM() -> i32 { return 2; }
fn T_FN() -> i32 { return 4; }
fn T_LET() -> i32 { return 5; }
fn T_RETURN() -> i32 { return 10; }
fn T_LPAREN() -> i32 { return 12; }
fn T_RPAREN() -> i32 { return 13; }
fn T_LBRACE() -> i32 { return 14; }
fn T_RBRACE() -> i32 { return 15; }
fn T_SEMI() -> i32 { return 18; }
fn T_PLUS() -> i32 { return 21; }
fn T_MINUS() -> i32 { return 22; }
fn T_STAR() -> i32 { return 23; }
fn T_EQ() -> i32 { return 25; }
fn T_ARROW() -> i32 { return 32; }

// ==================== AST NODE TYPES ====================

fn AST_NUM() -> i32 { return 1; }
fn AST_IDENT() -> i32 { return 2; }
fn AST_BINOP() -> i32 { return 3; }
fn AST_LET() -> i32 { return 6; }
fn AST_RETURN() -> i32 { return 5; }

fn OP_ADD() -> i32 { return 21; }
fn OP_MUL() -> i32 { return 23; }

// ==================== PARSER STATE ====================

// Simulated token stream for: let x = 2 + 3;
fn demo_token_stream() -> i32 {
    println("Token Stream:");
    println("  [0] T_LET (5)");
    println("  [1] T_IDENT (1) 'x'");
    println("  [2] T_EQ (25)");
    println("  [3] T_NUM (2) '2'");
    println("  [4] T_PLUS (21)");
    println("  [5] T_NUM (2) '3'");
    println("  [6] T_SEMI (18)");
    println("");
    return 0;
}

// ==================== TOKEN CONSUMPTION FUNCTIONS ====================

// Check if current token matches expected type
fn check_token(current_type: i32, expected_type: i32) -> i32 {
    if (current_type == expected_type) {
        return 1;
    }
    return 0;
}

// Advance to next token (simulated)
fn advance_token(pos: i32) -> i32 {
    return pos + 1;
}

// Peek at current token type (simulated)
fn peek_token(pos: i32) -> i32 {
    // Simulated token stream: let x = 2 + 3;
    if (pos == 0) { return T_LET(); }
    if (pos == 1) { return T_IDENT(); }
    if (pos == 2) { return T_EQ(); }
    if (pos == 3) { return T_NUM(); }
    if (pos == 4) { return T_PLUS(); }
    if (pos == 5) { return T_NUM(); }
    if (pos == 6) { return T_SEMI(); }
    return T_EOF();
}

// ==================== PARSER DEMONSTRATION ====================

fn demo_parsing_steps() -> i32 {
    println("=================================================");
    println("PARSING SIMULATION: let x = 2 + 3;");
    println("=================================================");
    println("");

    let pos = 0;
    let tok = 0;

    println("Step 1: Check for 'let' keyword");
    tok = peek_token(pos);
    print("  Current token: ");
    print_int(tok);
    print(" (expected: ");
    print_int(T_LET());
    println(")");

    if (check_token(tok, T_LET()) == 1) {
        println("  ✅ Match! Consuming T_LET");
        pos = advance_token(pos);
    }
    println("");

    println("Step 2: Check for identifier");
    tok = peek_token(pos);
    print("  Current token: ");
    print_int(tok);
    print(" (expected: ");
    print_int(T_IDENT());
    println(")");

    if (check_token(tok, T_IDENT()) == 1) {
        println("  ✅ Match! Consuming T_IDENT 'x'");
        pos = advance_token(pos);
    }
    println("");

    println("Step 3: Check for '=' operator");
    tok = peek_token(pos);
    print("  Current token: ");
    print_int(tok);
    print(" (expected: ");
    print_int(T_EQ());
    println(")");

    if (check_token(tok, T_EQ()) == 1) {
        println("  ✅ Match! Consuming T_EQ");
        pos = advance_token(pos);
    }
    println("");

    println("Step 4: Parse expression '2 + 3'");
    tok = peek_token(pos);
    print("  Current token: ");
    print_int(tok);
    println(" (T_NUM)");

    if (check_token(tok, T_NUM()) == 1) {
        println("  ✅ Found number '2'");
        pos = advance_token(pos);
    }

    tok = peek_token(pos);
    print("  Current token: ");
    print_int(tok);
    println(" (T_PLUS)");

    if (check_token(tok, T_PLUS()) == 1) {
        println("  ✅ Found operator '+'");
        pos = advance_token(pos);
    }

    tok = peek_token(pos);
    print("  Current token: ");
    print_int(tok);
    println(" (T_NUM)");

    if (check_token(tok, T_NUM()) == 1) {
        println("  ✅ Found number '3'");
        pos = advance_token(pos);
    }
    println("");

    println("Step 5: Check for semicolon");
    tok = peek_token(pos);
    print("  Current token: ");
    print_int(tok);
    println(" (T_SEMI)");

    if (check_token(tok, T_SEMI()) == 1) {
        println("  ✅ Match! Consuming T_SEMI");
        pos = advance_token(pos);
    }
    println("");

    println("=================================================");
    println("PARSING COMPLETE!");
    println("=================================================");
    println("Generated AST:");
    println("  LET");
    println("    name: 'x'");
    println("    value: BINOP (ADD)");
    println("      left: NUM (2)");
    println("      right: NUM (3)");
    println("");

    return 0;
}

// ==================== MAIN ====================

fn main() -> i32 {
    println("");
    println("=================================================");
    println("CHRONOS SELF-HOSTED PARSER v0.2");
    println("Token Consumption Functions");
    println("=================================================");
    println("");

    println("Parser Functions Implemented:");
    println("  ✅ check_token(current, expected) -> bool");
    println("  ✅ advance_token(pos) -> new_pos");
    println("  ✅ peek_token(pos) -> token_type");
    println("");

    demo_token_stream();
    demo_parsing_steps();

    println("=================================================");
    println("STATUS:");
    println("=================================================");
    println("  ✅ AST node types defined");
    println("  ✅ Token consumption functions implemented");
    println("  ✅ Step-by-step parsing demonstrated");
    println("  🔄 Next: Primary expression parsing");
    println("  ⏭️ Then: Binary operator precedence");
    println("");

    return 0;
}
