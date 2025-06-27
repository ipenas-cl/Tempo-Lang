╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 4: Gramáticas y Parsing

## 🎯 Objetivos de esta lección

- Entender qué son las gramáticas libres de contexto (CFG)
- Conocer los algoritmos de parsing LL(1) y LR
- Manejar precedencia y asociatividad de operadores
- Implementar un parser básico para expresiones aritméticas

## 🧠 Teoría: Gramáticas y Parsing (20%)

### Gramáticas Libres de Contexto (CFG)

Una gramática define la sintaxis de un lenguaje. Consta de:
- **Terminales**: Tokens del lexer (NUMBER, PLUS, etc.)
- **No-terminales**: Símbolos abstractos (Expression, Statement)
- **Producciones**: Reglas de reescritura
- **Símbolo inicial**: Por donde empieza el parse

**Ejemplo de gramática para expresiones:**
```
E → E + T | T
T → T * F | F  
F → ( E ) | NUMBER
```

### Parsing LL(1) - Top-Down

LL(1) significa:
- **L**: Lee de izquierda a derecha (Left-to-right)
- **L**: Derivación por la izquierda (Leftmost)
- **1**: Mira 1 token adelante (lookahead)

**Ventajas:**
- Simple de implementar
- Fácil de entender
- Genera buenos mensajes de error

**Desventajas:**
- No puede manejar recursión izquierda
- Gramáticas limitadas

### Parsing LR - Bottom-Up

LR construye el árbol desde las hojas hacia la raíz:
- **Shift**: Lee un token y lo pone en la pila
- **Reduce**: Aplica una regla de producción

**Ventajas:**
- Maneja más gramáticas
- Más eficiente
- Permite recursión izquierda

**Desventajas:**
- Más complejo
- Mensajes de error confusos

## 💻 Práctica: Implementando un Parser (60%)

### 1. Parser de Calculadora con Precedencia

Implementaremos un parser que respete precedencia: `*` y `/` antes que `+` y `-`.

```tempo
// Token types
enum TokenType {
    NUMBER,
    PLUS,
    MINUS,
    MULTIPLY,
    DIVIDE,
    LPAREN,
    RPAREN,
    EOF
}

struct Token {
    type: TokenType,
    value: string,
    position: i32
}

// Parser recursivo descendente
struct Parser {
    tokens: array<Token>,
    current: i32
}

// Gramática con precedencia:
// Expression → Term (('+' | '-') Term)*
// Term → Factor (('*' | '/') Factor)*
// Factor → NUMBER | '(' Expression ')'

function parse_expression(parser: Parser) -> i32 {
    let left = parse_term(parser);
    
    while (parser.current < parser.tokens.length) {
        let token = parser.tokens[parser.current];
        
        if (token.type == TokenType.PLUS) {
            parser.current += 1;
            let right = parse_term(parser);
            left = left + right;
        } else if (token.type == TokenType.MINUS) {
            parser.current += 1;
            let right = parse_term(parser);
            left = left - right;
        } else {
            break;
        }
    }
    
    return left;
}

function parse_term(parser: Parser) -> i32 {
    let left = parse_factor(parser);
    
    while (parser.current < parser.tokens.length) {
        let token = parser.tokens[parser.current];
        
        if (token.type == TokenType.MULTIPLY) {
            parser.current += 1;
            let right = parse_factor(parser);
            left = left * right;
        } else if (token.type == TokenType.DIVIDE) {
            parser.current += 1;
            let right = parse_factor(parser);
            left = left / right;
        } else {
            break;
        }
    }
    
    return left;
}

function parse_factor(parser: Parser) -> i32 {
    let token = parser.tokens[parser.current];
    
    if (token.type == TokenType.NUMBER) {
        parser.current += 1;
        return string_to_int(token.value);
    }
    
    if (token.type == TokenType.LPAREN) {
        parser.current += 1;  // Consumir '('
        let result = parse_expression(parser);
        
        // Esperar ')'
        if (parser.tokens[parser.current].type != TokenType.RPAREN) {
            panic("Expected ')' at position ${parser.current}");
        }
        parser.current += 1;
        return result;
    }
    
    panic("Unexpected token: ${token.value}");
}
```

### 2. Manejo de Asociatividad

La asociatividad determina cómo se agrupan operadores del mismo nivel:

```tempo
// Asociatividad izquierda (más común)
// 5 - 3 - 1 = (5 - 3) - 1 = 1

function parse_left_associative(parser: Parser) -> i32 {
    let left = parse_primary(parser);
    
    while (is_operator(peek(parser))) {
        let op = consume_token(parser);
        let right = parse_primary(parser);
        left = apply_operation(left, op, right);
    }
    
    return left;
}

// Asociatividad derecha (para exponenciación)
// 2 ^ 3 ^ 2 = 2 ^ (3 ^ 2) = 512

function parse_right_associative(parser: Parser) -> i32 {
    let left = parse_primary(parser);
    
    if (peek(parser).type == TokenType.POWER) {
        consume_token(parser);
        let right = parse_right_associative(parser);  // Recursión!
        return power(left, right);
    }
    
    return left;
}
```

### 3. Tabla de Precedencia

Una forma elegante de manejar precedencia:

```tempo
// Precedence-climbing algorithm
struct OpInfo {
    precedence: i32,
    left_associative: bool
}

const OPERATORS = {
    "+": OpInfo { precedence: 1, left_associative: true },
    "-": OpInfo { precedence: 1, left_associative: true },
    "*": OpInfo { precedence: 2, left_associative: true },
    "/": OpInfo { precedence: 2, left_associative: true },
    "^": OpInfo { precedence: 3, left_associative: false }
};

function parse_binary_expr(parser: Parser, min_prec: i32) -> i32 {
    let left = parse_primary(parser);
    
    while (true) {
        let token = peek(parser);
        if (!is_binary_op(token)) break;
        
        let op_info = OPERATORS[token.value];
        if (op_info.precedence < min_prec) break;
        
        consume_token(parser);
        
        let next_min_prec = op_info.precedence;
        if (op_info.left_associative) {
            next_min_prec += 1;
        }
        
        let right = parse_binary_expr(parser, next_min_prec);
        left = apply_op(left, token.value, right);
    }
    
    return left;
}
```

### 4. Parser Predictivo LL(1)

Construcción de tabla de parsing:

```tempo
// FIRST sets - qué tokens pueden empezar una producción
const FIRST = {
    "Expression": [NUMBER, LPAREN],
    "Term": [NUMBER, LPAREN],
    "Factor": [NUMBER, LPAREN]
};

// FOLLOW sets - qué tokens pueden seguir a un no-terminal
const FOLLOW = {
    "Expression": [EOF, RPAREN],
    "Term": [PLUS, MINUS, EOF, RPAREN],
    "Factor": [MULTIPLY, DIVIDE, PLUS, MINUS, EOF, RPAREN]
};

// Tabla de parsing LL(1)
// [No-terminal][Terminal] → Producción
const PARSE_TABLE = {
    "Expression": {
        NUMBER: "Expression → Term Expression'",
        LPAREN: "Expression → Term Expression'"
    },
    "Expression'": {
        PLUS: "Expression' → + Term Expression'",
        MINUS: "Expression' → - Term Expression'",
        EOF: "Expression' → ε",
        RPAREN: "Expression' → ε"
    }
    // ... más entradas ...
};

function ll1_parse(parser: Parser) -> AST {
    let stack = ["EOF", "Expression"];  // Pila con símbolo inicial
    let ast = AST { };
    
    while (stack.length > 1) {
        let top = stack.pop();
        let current = peek(parser);
        
        if (is_terminal(top)) {
            if (top == current.type) {
                consume_token(parser);
            } else {
                panic("Expected ${top}, found ${current.type}");
            }
        } else {
            // Es un no-terminal
            let production = PARSE_TABLE[top][current.type];
            if (!production) {
                panic("No production for ${top} with ${current.type}");
            }
            
            // Expandir producción en la pila (en orden inverso)
            let rhs = get_production_rhs(production);
            for (let i = rhs.length - 1; i >= 0; i--) {
                if (rhs[i] != "ε") {
                    stack.push(rhs[i]);
                }
            }
        }
    }
    
    return ast;
}
```

### 5. Manejo de Errores y Recuperación

```tempo
function parse_with_recovery(parser: Parser) -> Result<AST, array<Error>> {
    let errors = array<Error> { };
    let ast = AST { };
    
    while (parser.current < parser.tokens.length) {
        try {
            let stmt = parse_statement(parser);
            ast.statements.push(stmt);
        } catch (e: ParseError) {
            errors.push(e);
            
            // Recuperación: buscar siguiente punto de sincronización
            synchronize(parser);
        }
    }
    
    if (errors.length > 0) {
        return Result.Error(errors);
    }
    return Result.Ok(ast);
}

function synchronize(parser: Parser) {
    // Avanzar hasta encontrar un punto seguro para continuar
    while (parser.current < parser.tokens.length) {
        let token = parser.tokens[parser.current];
        
        // Puntos de sincronización comunes
        if (token.type == TokenType.SEMICOLON ||
            token.type == TokenType.RBRACE ||
            is_statement_start(peek(parser))) {
            parser.current += 1;
            break;
        }
        
        parser.current += 1;
    }
}
```

## 🏋️ Ejercicios (20%)

### Ejercicio 1: Extender la Calculadora
Agrega soporte para:
1. Operador de módulo `%`
2. Operador de exponenciación `^` (asociativo a la derecha)
3. Operadores unarios `-` y `+`

### Ejercicio 2: Gramática Ambigua
Esta gramática es ambigua:
```
E → E + E | E * E | NUMBER
```

Para la expresión `2 + 3 * 4`:
1. Dibuja los dos árboles de parse posibles
2. Reescribe la gramática para eliminar la ambigüedad
3. ¿Cuál interpretación es la correcta?

### Ejercicio 3: Parser para Declaraciones
Implementa un parser para declaraciones simples:
```
Declaration → let IDENTIFIER = Expression
            | const IDENTIFIER = Expression
```

### Ejercicio 4: Detección de Recursión Izquierda
¿Cuáles de estas gramáticas tienen recursión izquierda?
```
1. A → A a | b
2. A → B a | c
   B → A b | d
3. A → a A | b
4. A → B C
   B → A | ε
```

### Ejercicio 5: Construcción de FIRST y FOLLOW
Para esta gramática:
```
S → A B
A → a A | ε
B → b B | c
```
Calcula:
1. FIRST(A), FIRST(B), FIRST(S)
2. FOLLOW(A), FOLLOW(B)

## 📚 Lecturas recomendadas

1. **"Compilers: Principles, Techniques, and Tools"** - Capítulo 4: Syntax Analysis
2. **"Modern Compiler Implementation"** - Parsing algorithms
3. **"Parsing Techniques"** de Grune & Jacobs - Comprehensive guide

## 🎯 Para la próxima clase

1. Implementa un parser completo para expresiones aritméticas
2. Estudia la arquitectura x86-64 básica
3. Piensa: ¿Cómo traducirías expresiones a código ensamblador?

## 💡 Dato curioso

El algoritmo LR fue inventado por Donald Knuth en 1965. Era considerado demasiado complejo para implementar hasta que Frank DeRemer inventó LALR en 1969, haciéndolo práctico. ¡Yacc (1975) popularizó los generadores de parsers LR!

---

**Resumen**: Las gramáticas definen la sintaxis de los lenguajes. LL(1) es simple pero limitado, LR es poderoso pero complejo. La precedencia y asociatividad son cruciales para parsear expresiones correctamente.

[← Lección 3: Autómatas](leccion3-automatas.md) | [Lección 5: Assembly x86-64 →](leccion5-assembly.md)