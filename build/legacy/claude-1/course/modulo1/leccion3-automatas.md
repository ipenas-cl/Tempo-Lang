╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 3: Autómatas y Expresiones Regulares

## 🎯 Objetivos de esta lección

- Dominar autómatas finitos deterministas (DFA) y no deterministas (NFA)
- Escribir y optimizar expresiones regulares
- Implementar un lexer real para Tempo
- Entender la relación entre regex, autómatas y análisis léxico

## 🧠 Teoría: Autómatas y Regex (20%)

### Autómatas Finitos

Un **autómata finito** es una máquina abstracta con:
- Estados finitos
- Transiciones entre estados
- Estado inicial
- Estados de aceptación

**Tipos principales:**
1. **DFA** (Deterministic Finite Automaton): Una transición por símbolo
2. **NFA** (Non-deterministic Finite Automaton): Múltiples transiciones posibles

### Expresiones Regulares

Las **regex** describen patrones de texto usando operadores:
- **Concatenación**: `ab` (a seguido de b)
- **Alternación**: `a|b` (a o b)
- **Kleene star**: `a*` (cero o más a's)
- **Plus**: `a+` (una o más a's)
- **Opcional**: `a?` (cero o una a)

### Equivalencia fundamental

```
Regex ←→ NFA ←→ DFA ←→ Código
```

Todo lenguaje regular puede ser:
1. Descrito por una regex
2. Reconocido por un NFA
3. Reconocido por un DFA
4. Implementado en código

## 💻 Práctica: Construyendo un Lexer (60%)

### 1. De Regex a Autómata

**Ejemplo: Reconocer números flotantes**

Regex: `[+-]?[0-9]+(\.[0-9]+)?`

```tempo
// Estado del autómata
type State = enum {
    START,
    SIGN,
    INTEGER,
    DOT,
    FRACTION,
    ACCEPT,
    REJECT
}

// DFA para números flotantes
function is_float_dfa(input: string) -> bool {
    let state = State.START;
    
    for (char in input) {
        state = match (state, char) {
            (START, '+') | (START, '-') => SIGN,
            (START, '0'..'9') => INTEGER,
            (SIGN, '0'..'9') => INTEGER,
            (INTEGER, '0'..'9') => INTEGER,
            (INTEGER, '.') => DOT,
            (DOT, '0'..'9') => FRACTION,
            (FRACTION, '0'..'9') => FRACTION,
            _ => REJECT
        };
        
        if (state == REJECT) {
            return false;
        }
    }
    
    return state == INTEGER || state == FRACTION;
}

// Pruebas
assert(is_float_dfa("123"));        // true
assert(is_float_dfa("-45.67"));     // true
assert(is_float_dfa("+.5"));        // false
assert(!is_float_dfa("12.34.56"));  // false
```

### 2. Motor de Expresiones Regulares

```tempo
// Mini motor de regex
type RegexNode = enum {
    Char(char),
    Concat(Box<RegexNode>, Box<RegexNode>),
    Alt(Box<RegexNode>, Box<RegexNode>),
    Star(Box<RegexNode>),
    Plus(Box<RegexNode>)
}

// Compilar regex a NFA
function regex_to_nfa(pattern: string) -> NFA {
    let tokens = tokenize_regex(pattern);
    let ast = parse_regex(tokens);
    return build_nfa(ast);
}

// Thompson's construction
function build_nfa(node: RegexNode) -> NFA {
    match node {
        Char(c) => {
            // NFA simple: →(start)--c-->(accept)
            let start = new_state();
            let accept = new_state();
            return NFA {
                start: start,
                accept: [accept],
                transitions: [(start, Some(c), accept)]
            };
        },
        Concat(left, right) => {
            let nfa1 = build_nfa(left);
            let nfa2 = build_nfa(right);
            // Conectar accept de nfa1 con start de nfa2
            return concatenate_nfas(nfa1, nfa2);
        },
        Alt(left, right) => {
            let nfa1 = build_nfa(left);
            let nfa2 = build_nfa(right);
            // Nuevo start con ε-transiciones
            return alternate_nfas(nfa1, nfa2);
        },
        Star(inner) => {
            let nfa = build_nfa(inner);
            // Añadir loop con ε-transiciones
            return kleene_star_nfa(nfa);
        }
    }
}
```

### 3. Lexer Completo para Tempo

```tempo
// Token types de Tempo
type TokenType = enum {
    // Palabras clave
    FUNCTION, LET, IF, ELSE, WHILE, FOR, RETURN, WITHIN,
    
    // Tipos
    I8, I16, I32, I64, F32, F64, BOOL, STRING,
    
    // Literales
    INT_LITERAL, FLOAT_LITERAL, STRING_LITERAL, BOOL_LITERAL,
    
    // Identificadores
    IDENTIFIER,
    
    // Operadores
    PLUS, MINUS, STAR, SLASH, PERCENT,
    EQ, NE, LT, GT, LE, GE,
    AND, OR, NOT,
    ASSIGN,
    
    // Delimitadores
    LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET,
    SEMICOLON, COMMA, DOT, ARROW,
    
    // Especiales
    EOF, ERROR
}

type Token = struct {
    type: TokenType,
    lexeme: string,
    line: i32,
    column: i32,
    // Para análisis de tiempo
    timing_info: Option<TimingConstraint>
}

// Definición de patrones
const PATTERNS: [(string, TokenType)] = [
    // Palabras clave (orden importa!)
    ("function", FUNCTION),
    ("let", LET),
    ("if", IF),
    ("else", ELSE),
    ("while", WHILE),
    ("for", FOR),
    ("return", RETURN),
    ("within", WITHIN),
    
    // Tipos
    ("i8", I8),
    ("i16", I16),
    ("i32", I32),
    ("i64", I64),
    ("f32", F32),
    ("f64", F64),
    ("bool", BOOL),
    ("string", STRING),
    
    // Literales
    ("[0-9]+", INT_LITERAL),
    ("[0-9]+\\.[0-9]+", FLOAT_LITERAL),
    ("\"([^\"\\\\]|\\\\.)*\"", STRING_LITERAL),
    ("true|false", BOOL_LITERAL),
    
    // Identificadores
    ("[a-zA-Z_][a-zA-Z0-9_]*", IDENTIFIER),
    
    // Operadores de 2 caracteres
    ("==", EQ),
    ("!=", NE),
    ("<=", LE),
    (">=", GE),
    ("&&", AND),
    ("||", OR),
    ("->", ARROW),
    
    // Operadores de 1 caracter
    ("\\+", PLUS),
    ("-", MINUS),
    ("\\*", STAR),
    ("/", SLASH),
    ("%", PERCENT),
    ("<", LT),
    (">", GT),
    ("!", NOT),
    ("=", ASSIGN),
    
    // Delimitadores
    ("\\(", LPAREN),
    ("\\)", RPAREN),
    ("\\{", LBRACE),
    ("\\}", RBRACE),
    ("\\[", LBRACKET),
    ("\\]", RBRACKET),
    (";", SEMICOLON),
    (",", COMMA),
    ("\\.", DOT)
];

// Lexer principal
type Lexer = struct {
    input: string,
    position: i32,
    line: i32,
    column: i32,
    tokens: Vec<Token>
}

impl Lexer {
    function new(input: string) -> Lexer {
        return Lexer {
            input: input,
            position: 0,
            line: 1,
            column: 1,
            tokens: Vec::new()
        };
    }
    
    function scan_tokens(&mut self) -> Vec<Token> within O(n) {
        while (!self.is_at_end()) {
            self.skip_whitespace();
            
            if (self.is_at_end()) {
                break;
            }
            
            // Intentar comentarios
            if (self.match_comment()) {
                continue;
            }
            
            // Intentar cada patrón
            let matched = false;
            let start_pos = self.position;
            let start_col = self.column;
            
            for ((pattern, token_type) in PATTERNS) {
                if (let Some(lexeme) = self.match_pattern(pattern)) {
                    self.tokens.push(Token {
                        type: token_type,
                        lexeme: lexeme,
                        line: self.line,
                        column: start_col,
                        timing_info: None
                    });
                    matched = true;
                    break;
                }
            }
            
            if (!matched) {
                // Error: carácter no reconocido
                self.tokens.push(Token {
                    type: ERROR,
                    lexeme: self.input[self.position..self.position+1],
                    line: self.line,
                    column: self.column
                });
                self.advance();
            }
        }
        
        // Añadir EOF
        self.tokens.push(Token {
            type: EOF,
            lexeme: "",
            line: self.line,
            column: self.column
        });
        
        return self.tokens;
    }
    
    function match_pattern(&mut self, pattern: string) -> Option<string> {
        // Aquí usaríamos nuestro motor de regex
        // Por simplicidad, implementamos algunos casos manualmente
        
        // Caso especial: keywords e identificadores
        if (pattern == "[a-zA-Z_][a-zA-Z0-9_]*") {
            return self.scan_identifier();
        }
        
        // Caso especial: números
        if (pattern == "[0-9]+") {
            return self.scan_integer();
        }
        
        // Caso especial: strings
        if (pattern == "\"([^\"\\\\]|\\\\.)*\"") {
            return self.scan_string();
        }
        
        // Para patrones simples (literales)
        if (self.match_literal(pattern)) {
            return Some(pattern);
        }
        
        return None;
    }
    
    function scan_identifier(&mut self) -> Option<string> {
        let start = self.position;
        
        // Primer carácter debe ser letra o _
        if (!self.current().is_alphabetic() && self.current() != '_') {
            return None;
        }
        
        self.advance();
        
        // Siguientes pueden ser letra, dígito o _
        while (self.current().is_alphanumeric() || self.current() == '_') {
            self.advance();
        }
        
        return Some(self.input[start..self.position]);
    }
    
    function scan_integer(&mut self) -> Option<string> {
        let start = self.position;
        
        if (!self.current().is_digit()) {
            return None;
        }
        
        while (self.current().is_digit()) {
            self.advance();
        }
        
        // No consumir el punto si es un float
        if (self.current() == '.' && self.peek().is_digit()) {
            return None;  // Es un float, no un int
        }
        
        return Some(self.input[start..self.position]);
    }
}
```

### 4. Optimización de DFA

```tempo
// Minimización de DFA usando algoritmo de Hopcroft
function minimize_dfa(dfa: DFA) -> DFA {
    // Paso 1: Eliminar estados inalcanzables
    let reachable = find_reachable_states(dfa);
    
    // Paso 2: Partición inicial (finales vs no finales)
    let mut partitions = [
        dfa.final_states,
        dfa.states - dfa.final_states
    ];
    
    // Paso 3: Refinar particiones
    let mut changed = true;
    while (changed) {
        changed = false;
        let mut new_partitions = [];
        
        for (partition in partitions) {
            let splits = split_partition(partition, partitions, dfa);
            if (splits.length > 1) {
                changed = true;
            }
            new_partitions.extend(splits);
        }
        
        partitions = new_partitions;
    }
    
    // Paso 4: Construir DFA mínimo
    return build_minimal_dfa(partitions, dfa);
}

// Ejemplo: minimizar DFA para identificadores
function optimize_identifier_dfa() {
    // DFA original (muchos estados)
    let original = DFA {
        states: 100,  // Estados para cada longitud
        transitions: /* ... */,
        final_states: /* todos excepto el inicial */
    };
    
    // DFA minimizado (solo 2 estados!)
    let minimal = minimize_dfa(original);
    assert(minimal.states == 2);  // START y ACCEPTING
}
```

### 5. Generador de Lexer desde especificación

```tempo
// DSL para definir lexers
type LexerSpec = struct {
    rules: Vec<(string, string, TokenType)>,  // (name, pattern, type)
    keywords: Vec<(string, TokenType)>,
    skip: Vec<string>,  // Whitespace, comments
}

// Generador de código
function generate_lexer(spec: LexerSpec) -> string {
    let mut code = "// Generated lexer\n\n";
    
    // Generar enums
    code += "type TokenType = enum {\n";
    for ((_, _, token_type) in spec.rules) {
        code += "    ${token_type},\n";
    }
    code += "}\n\n";
    
    // Generar tabla de patrones
    code += "const PATTERNS = [\n";
    for ((name, pattern, token_type) in spec.rules) {
        code += "    // ${name}\n";
        code += "    (\"${pattern}\", ${token_type}),\n";
    }
    code += "];\n\n";
    
    // Generar función de scanning
    code += generate_scanner_function(spec);
    
    return code;
}

// Uso del generador
function create_tempo_lexer() {
    let spec = LexerSpec {
        rules: [
            ("identifier", "[a-zA-Z_][a-zA-Z0-9_]*", IDENTIFIER),
            ("integer", "[0-9]+", INT_LITERAL),
            ("float", "[0-9]+\\.[0-9]+", FLOAT_LITERAL),
            ("string", "\"([^\"\\\\]|\\\\.)*\"", STRING_LITERAL),
        ],
        keywords: [
            ("function", FUNCTION),
            ("let", LET),
            ("if", IF),
        ],
        skip: ["[ \\t\\r\\n]+", "//.*", "/\\*.*?\\*/"]
    };
    
    let lexer_code = generate_lexer(spec);
    write_file("generated_lexer.tempo", lexer_code);
}
```

### 6. Análisis de rendimiento

```tempo
// Benchmark de diferentes implementaciones
function benchmark_lexers() {
    let input = read_file("large_program.tempo");  // 100K líneas
    
    // Método 1: Regex compiladas
    let t1 = measure_time(|| {
        let lexer1 = RegexLexer::new();
        lexer1.tokenize(input);
    });
    
    // Método 2: DFA generado
    let t2 = measure_time(|| {
        let lexer2 = DFALexer::new();
        lexer2.tokenize(input);
    });
    
    // Método 3: Hand-written
    let t3 = measure_time(|| {
        let lexer3 = HandWrittenLexer::new();
        lexer3.tokenize(input);
    });
    
    print("Regex: ${t1}ms");        // ~500ms
    print("DFA: ${t2}ms");          // ~100ms
    print("Hand-written: ${t3}ms"); // ~50ms
    
    // El DFA es un buen balance entre mantenibilidad y performance
}
```

## 🏋️ Ejercicios (20%)

### Ejercicio 1: Construir autómatas
Dibuja el DFA para reconocer:
1. Strings que contienen "abc" como substring
2. Números binarios divisibles por 3
3. Identificadores de C (empiezan con letra o _, continúan con letra, dígito o _)

### Ejercicio 2: Regex avanzadas
Escribe expresiones regulares para:
1. URLs válidas (http/https)
2. Fechas en formato ISO (YYYY-MM-DD)
3. Direcciones de email válidas
4. Números hexadecimales de C (0x...)

### Ejercicio 3: Lexer para mini-lenguaje
Implementa un lexer completo para este lenguaje:
```
// Mini-lenguaje
var x = 10;
if (x > 5) {
    print("Grande");
} else {
    print("Pequeño");
}
```

### Ejercicio 4: Optimización
Dado este NFA, conviértelo a DFA y luego minimízalo:
```
Estados: {q0, q1, q2}
Alfabeto: {a, b}
Transiciones:
  q0 --a--> q1
  q0 --ε--> q2
  q1 --b--> q2
  q2 --a--> q2
  q2 --b--> q2
Inicial: q0
Finales: {q2}
```

### Ejercicio 5: Análisis de complejidad
Para cada implementación, analiza:
1. Complejidad temporal de tokenización
2. Uso de memoria
3. Facilidad de mantenimiento
4. Casos donde cada una es óptima

## 📚 Referencias

1. **"Compilers: Principles, Techniques, and Tools"** - Aho, Sethi, Ullman (Dragon Book)
2. **"Flex & Bison"** - John Levine
3. **Tool**: [regex101.com](https://regex101.com) - Para probar regex
4. **Paper**: "Regular Expression Matching Can Be Simple And Fast" - Russ Cox

## 💡 Dato curioso

Ken Thompson (creador de Unix) inventó el algoritmo de construcción de NFA desde regex en 1968. Su implementación original en ed/grep sigue siendo una de las más elegantes. Fun fact: el comando "grep" significa "Global Regular Expression Print"!

---

**Resumen**: Los autómatas finitos y las expresiones regulares son la base del análisis léxico. Un buen lexer es determinista, rápido y mantenible. Para Tempo, usamos un DFA optimizado que garantiza tiempo O(n) para tokenización.

[← Lección 2](leccion2-teoria.md) | [Índice](../README.md) | [Lección 4: Parsing →](leccion4-parsing.md)