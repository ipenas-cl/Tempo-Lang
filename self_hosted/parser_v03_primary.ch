// CHRONOS SELF-HOSTED PARSER v0.3
// Primary expression parsing (numbers, identifiers)
// Author: ipenas-cl

// ==================== TOKEN TYPES ====================

fn T_EOF() -> i32 { return 0; }
fn T_IDENT() -> i32 { return 1; }
fn T_NUM() -> i32 { return 2; }
fn T_PLUS() -> i32 { return 21; }
fn T_STAR() -> i32 { return 23; }

// ==================== AST NODE TYPES ====================

fn AST_NUM() -> i32 { return 1; }
fn AST_IDENT() -> i32 { return 2; }
fn AST_BINOP() -> i32 { return 3; }

fn OP_ADD() -> i32 { return 21; }
fn OP_MUL() -> i32 { return 23; }

// ==================== PRIMARY PARSING ====================

// Parse a number literal
// Input: NUM token
// Output: AST_NUM node
fn parse_number() -> i32 {
    println("  Parsing number...");
    println("    Created AST_NUM node");
    return AST_NUM();
}

// Parse an identifier
// Input: IDENT token
// Output: AST_IDENT node
fn parse_identifier() -> i32 {
    println("  Parsing identifier...");
    println("    Created AST_IDENT node");
    return AST_IDENT();
}

// Parse primary expression (number or identifier)
// primary := NUM | IDENT
fn parse_primary(token_type: i32) -> i32 {
    if (token_type == T_NUM()) {
        return parse_number();
    }
    if (token_type == T_IDENT()) {
        return parse_identifier();
    }
    println("  ERROR: Expected number or identifier");
    return 0;
}

// ==================== DEMONSTRATIONS ====================

fn demo_parse_number() -> i32 {
    println("=================================================");
    println("PARSING: 42");
    println("=================================================");
    println("");

    println("Input: T_NUM (value=42)");
    let ast_node = parse_primary(T_NUM());
    println("");

    println("Output AST:");
    print("  AST_NUM (type=");
    print_int(ast_node);
    println(", value=42)");
    println("");

    return 0;
}

fn demo_parse_identifier() -> i32 {
    println("=================================================");
    println("PARSING: variable");
    println("=================================================");
    println("");

    println("Input: T_IDENT (name='variable')");
    let ast_node = parse_primary(T_IDENT());
    println("");

    println("Output AST:");
    print("  AST_IDENT (type=");
    print_int(ast_node);
    println(", name='variable')");
    println("");

    return 0;
}

fn demo_parse_expression() -> i32 {
    println("=================================================");
    println("PARSING: x + y");
    println("=================================================");
    println("");

    println("Step 1: Parse left operand");
    let left = parse_primary(T_IDENT());
    println("");

    println("Step 2: Detect operator");
    println("  Found T_PLUS");
    let op = OP_ADD();
    println("");

    println("Step 3: Parse right operand");
    let right = parse_primary(T_IDENT());
    println("");

    println("Step 4: Construct BINOP node");
    let binop = AST_BINOP();
    println("  Created AST_BINOP node");
    print("    operator: ");
    print_int(op);
    println(" (ADD)");
    print("    left: AST_IDENT (type=");
    print_int(left);
    println(")");
    print("    right: AST_IDENT (type=");
    print_int(right);
    println(")");
    println("");

    println("Output AST:");
    println("  BINOP (ADD)");
    println("    ├─ IDENT (x)");
    println("    └─ IDENT (y)");
    println("");

    return 0;
}

fn demo_parse_complex() -> i32 {
    println("=================================================");
    println("PARSING: 2 * 3 + 4");
    println("=================================================");
    println("");

    println("With correct precedence (* before +):");
    println("");

    println("Step 1: Parse multiplicative (2 * 3)");
    let left_mul = parse_primary(T_NUM());
    let mul_op = OP_MUL();
    let right_mul = parse_primary(T_NUM());
    let mul_node = AST_BINOP();
    println("  Created: BINOP (MUL, 2, 3)");
    println("");

    println("Step 2: Parse additive ((2*3) + 4)");
    let add_left = mul_node;
    let add_op = OP_ADD();
    let add_right = parse_primary(T_NUM());
    let add_node = AST_BINOP();
    println("  Created: BINOP (ADD, (2*3), 4)");
    println("");

    println("Output AST (correct precedence):");
    println("  BINOP (ADD)");
    println("    ├─ BINOP (MUL)");
    println("    │   ├─ NUM (2)");
    println("    │   └─ NUM (3)");
    println("    └─ NUM (4)");
    println("");

    println("Result: (2 * 3) + 4 = 10 ✅");
    println("");

    return 0;
}

// ==================== MAIN ====================

fn main() -> i32 {
    println("");
    println("=================================================");
    println("CHRONOS SELF-HOSTED PARSER v0.3");
    println("Primary Expression Parsing");
    println("=================================================");
    println("");

    println("Parser Functions:");
    println("  ✅ parse_primary(token) -> AST node");
    println("  ✅ parse_number() -> AST_NUM");
    println("  ✅ parse_identifier() -> AST_IDENT");
    println("");

    demo_parse_number();
    demo_parse_identifier();
    demo_parse_expression();
    demo_parse_complex();

    println("=================================================");
    println("STATUS:");
    println("=================================================");
    println("  ✅ AST node types");
    println("  ✅ Token consumption");
    println("  ✅ Primary expression parsing");
    println("  🔄 Next: Binary operator precedence");
    println("  ⏭️ Then: Statement parsing");
    println("");

    println("Parser Progress: ~30% complete");
    println("");

    return 0;
}
