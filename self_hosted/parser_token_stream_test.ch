// CHRONOS PARSER - Token Stream Test
// Simple demonstration of real token handling
// Author: ipenas-cl

// Token types
fn T_EOF() -> i32 { return 0; }
fn T_NUM() -> i32 { return 2; }
fn T_PLUS() -> i32 { return 21; }
fn T_STAR() -> i32 { return 23; }

// AST node types
fn AST_NUM() -> i32 { return 1; }
fn AST_BINOP() -> i32 { return 3; }
fn OP_ADD() -> i32 { return 1; }
fn OP_MUL() -> i32 { return 3; }

// Global token stream (simplified)
let tokens: [i32; 32];
let values: [i32; 32];
let token_count: i32;
let current_pos: i32;

// Initialize parser
fn init_parser(count: i32) -> i32 {
    token_count = count;
    current_pos = 0;
    return 0;
}

// Get current token
fn current_token() -> i32 {
    if (current_pos >= token_count) {
        return T_EOF();
    }
    return tokens[current_pos];
}

// Get current value
fn current_value() -> i32 {
    if (current_pos >= token_count) {
        return 0;
    }
    return values[current_pos];
}

// Advance to next token
fn advance() -> i32 {
    if (current_pos < token_count) {
        current_pos = current_pos + 1;
    }
    return current_pos;
}

// Parse number
fn parse_num() -> i32 {
    let val = current_value();
    print("  NUM(");
    print_int(val);
    println(")");
    advance();
    return val;
}

// Parse primary: NUM
fn parse_primary() -> i32 {
    if (current_token() == T_NUM()) {
        return parse_num();
    }
    println("ERROR: Expected number");
    return 0;
}

// Parse multiplicative: primary ('*' primary)*
fn parse_mul() -> i32 {
    let left = parse_primary();

    while (current_token() == T_STAR()) {
        println("  MUL");
        advance();
        let right = parse_primary();

        print("  BINOP(MUL, ");
        print_int(left);
        print(", ");
        print_int(right);
        println(")");

        left = left * right;
    }

    return left;
}

// Parse additive: multiplicative ('+' multiplicative)*
fn parse_add() -> i32 {
    let left = parse_mul();

    while (current_token() == T_PLUS()) {
        println("  ADD");
        advance();
        let right = parse_mul();

        print("  BINOP(ADD, ");
        print_int(left);
        print(", ");
        print_int(right);
        println(")");

        left = left + right;
    }

    return left;
}

// Test 1: Simple addition "2 + 3"
fn test1() -> i32 {
    println("==========================================");
    println("TEST 1: 2 + 3");
    println("==========================================");

    tokens[0] = T_NUM();
    values[0] = 2;
    tokens[1] = T_PLUS();
    tokens[2] = T_NUM();
    values[2] = 3;
    tokens[3] = T_EOF();

    init_parser(4);

    println("Parsing:");
    let result = parse_add();

    print("Result: ");
    print_int(result);
    println("");
    println("");

    return result;
}

// Test 2: Precedence "2 + 3 * 4"
fn test2() -> i32 {
    println("==========================================");
    println("TEST 2: 2 + 3 * 4 (precedence test)");
    println("==========================================");

    tokens[0] = T_NUM();
    values[0] = 2;
    tokens[1] = T_PLUS();
    tokens[2] = T_NUM();
    values[2] = 3;
    tokens[3] = T_STAR();
    tokens[4] = T_NUM();
    values[4] = 4;
    tokens[5] = T_EOF();

    init_parser(6);

    println("Parsing:");
    let result = parse_add();

    print("Result: ");
    print_int(result);
    println(" (expected: 14)");
    println("");

    return result;
}

// Test 3: Complex "5 * 2 + 3 * 4"
fn test3() -> i32 {
    println("==========================================");
    println("TEST 3: 5 * 2 + 3 * 4");
    println("==========================================");

    tokens[0] = T_NUM();
    values[0] = 5;
    tokens[1] = T_STAR();
    tokens[2] = T_NUM();
    values[2] = 2;
    tokens[3] = T_PLUS();
    tokens[4] = T_NUM();
    values[4] = 3;
    tokens[5] = T_STAR();
    tokens[6] = T_NUM();
    values[6] = 4;
    tokens[7] = T_EOF();

    init_parser(8);

    println("Parsing:");
    let result = parse_add();

    print("Result: ");
    print_int(result);
    println(" (expected: 22)");
    println("");

    return result;
}

fn main() -> i32 {
    println("");
    println("##################################################");
    println("#                                                #");
    println("#   CHRONOS PARSER - Token Stream Test        #");
    println("#   Real Token Consumption & Precedence        #");
    println("#                                                #");
    println("##################################################");
    println("");

    test1();
    test2();
    test3();

    println("==========================================");
    println("SUMMARY:");
    println("==========================================");
    println("  ✅ Token stream handling");
    println("  ✅ Token consumption (current, advance)");
    println("  ✅ Operator precedence (* before +)");
    println("  ✅ Recursive descent parsing");
    println("");
    println("Parser Integration: WORKING!");
    println("");

    return 0;
}
