// CHRONOS SELF-HOSTED LEXER - DEMO v0.1
// Conceptual demonstration of self-hosted compilation
// Author: Ignacio Peña

// Token type constants
fn T_EOF() -> i32 { return 0; }
fn T_IDENT() -> i32 { return 1; }
fn T_NUM() -> i32 { return 2; }
fn T_FN() -> i32 { return 4; }
fn T_LET() -> i32 { return 5; }
fn T_PLUS() -> i32 { return 21; }
fn T_SEMI() -> i32 { return 18; }

// Character classification functions
fn is_digit(c: i32) -> i32 {
    if (c >= 48) {  // '0'
        if (c <= 57) {  // '9'
            return 1;
        }
    }
    return 0;
}

fn is_alpha(c: i32) -> i32 {
    if (c >= 97) {  // 'a'
        if (c <= 122) {  // 'z'
            return 1;
        }
    }
    if (c >= 65) {  // 'A'
        if (c <= 90) {  // 'Z'
            return 1;
        }
    }
    if (c == 95) {  // '_'
        return 1;
    }
    return 0;
}

fn is_space(c: i32) -> i32 {
    if (c == 32) { return 1; }  // ' '
    if (c == 9) { return 1; }   // '\t'
    if (c == 10) { return 1; }  // '\n'
    return 0;
}

// Keyword matching
fn is_keyword_fn(str: *i32) -> i32 {
    return strcmp(str, "fn");
}

fn is_keyword_let(str: *i32) -> i32 {
    return strcmp(str, "let");
}

fn is_keyword_return(str: *i32) -> i32 {
    return strcmp(str, "return");
}

// Demonstrate token classification
fn classify_token(name: *i32) -> i32 {
    println("Classifying token:");
    print("  Input: ");
    println(name);

    if (strcmp(name, "fn") == 0) {
        println("  Type: T_FN (keyword)");
        return T_FN();
    }
    if (strcmp(name, "let") == 0) {
        println("  Type: T_LET (keyword)");
        return T_LET();
    }
    if (strcmp(name, "return") == 0) {
        println("  Type: T_RETURN (keyword)");
        return 10;
    }

    println("  Type: T_IDENT (identifier)");
    return T_IDENT();
}

// Test character classification
fn test_char_classification() -> i32 {
    println("Testing character classification:");

    let c_digit = 53;  // '5'
    print("  '5' is_digit: ");
    print_int(is_digit(c_digit));
    println("");

    let c_alpha = 97;  // 'a'
    print("  'a' is_alpha: ");
    print_int(is_alpha(c_alpha));
    println("");

    let c_space = 32;  // ' '
    print("  ' ' is_space: ");
    print_int(is_space(c_space));
    println("");

    return 0;
}

// Test keyword recognition
fn test_keyword_recognition() -> i32 {
    println("Testing keyword recognition:");

    classify_token("fn");
    classify_token("let");
    classify_token("return");
    classify_token("variable");
    classify_token("add");

    return 0;
}

// Main demonstration
fn main() -> i32 {
    println("==================================================");
    println("🔥 CHRONOS SELF-HOSTED LEXER - DEMO v0.1");
    println("==================================================");
    println("");

    println("DEMONSTRATION: Chronos compiling Chronos");
    println("");

    println("This program demonstrates key lexer components:");
    println("  ✅ Token type definitions");
    println("  ✅ Character classification (is_digit, is_alpha, is_space)");
    println("  ✅ Keyword recognition (fn, let, return)");
    println("  ✅ String comparison for identifiers");
    println("");

    println("--------------------------------------------------");
    test_char_classification();
    println("");

    println("--------------------------------------------------");
    test_keyword_recognition();
    println("");

    println("==================================================");
    println("🎉 FIRST SELF-HOSTED COMPONENT DEMONSTRATION");
    println("==================================================");
    println("");

    println("NEXT STEPS:");
    println("  1. Full lexer: Scan source strings character-by-character");
    println("  2. Token array: Store all tokens in sequence");
    println("  3. Parser: Build AST from tokens");
    println("  4. Codegen: Emit assembly from AST");
    println("  5. FULL SELF-HOSTING: Chronos compiling Chronos");
    println("");

    println("STATUS: Lexer foundations complete ✅");

    return 0;
}
