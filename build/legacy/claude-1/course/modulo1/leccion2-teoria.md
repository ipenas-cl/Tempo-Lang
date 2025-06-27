╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 2: Teoría de Lenguajes

## 🎯 Objetivos de esta lección

- Entender qué es un lenguaje formal y su importancia en compiladores
- Dominar las gramáticas formales y su notación
- Conocer la jerarquía de Chomsky y dónde encaja cada tipo
- Aplicar estos conceptos al diseño de Tempo

## 🧠 Teoría: Lenguajes Formales (20%)

### ¿Qué es un lenguaje formal?

Un **lenguaje formal** es un conjunto de cadenas construidas con un alfabeto finito siguiendo reglas precisas. A diferencia del lenguaje natural (español, inglés), no hay ambigüedad.

**Ejemplos cotidianos:**
- Números de teléfono: `+52 (555) 123-4567`
- Emails: `usuario@dominio.com`
- Placas de auto: `ABC-123`

### Componentes fundamentales

1. **Alfabeto (Σ)**: Conjunto finito de símbolos
   - Binario: Σ = {0, 1}
   - Decimal: Σ = {0, 1, 2, ..., 9}
   - ASCII: Σ = {a, b, ..., z, A, B, ..., Z, 0, 1, ..., 9, +, -, *, ...}

2. **Cadena**: Secuencia finita de símbolos del alfabeto
   - ε (epsilon) = cadena vacía
   - |w| = longitud de la cadena w

3. **Lenguaje (L)**: Conjunto de cadenas válidas
   - L = {w | w satisface ciertas propiedades}

### Gramáticas Formales

Una **gramática** G = (V, T, P, S) donde:
- **V**: Variables (no-terminales)
- **T**: Terminales (alfabeto)
- **P**: Producciones (reglas)
- **S**: Símbolo inicial

### La Jerarquía de Chomsky

```
┌─────────────────────────────────────┐
│     Tipo 0: Recursivamente          │
│         Enumerables                 │
│  ┌─────────────────────────────┐   │
│  │   Tipo 1: Sensibles al      │   │
│  │       Contexto              │   │
│  │  ┌─────────────────────┐   │   │
│  │  │  Tipo 2: Libres de  │   │   │
│  │  │     Contexto        │   │   │
│  │  │  ┌─────────────┐   │   │   │
│  │  │  │   Tipo 3:   │   │   │   │
│  │  │  │  Regulares  │   │   │   │
│  │  │  └─────────────┘   │   │   │
│  │  └─────────────────────┘   │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## 💻 Práctica: Implementando Gramáticas (60%)

### 1. Gramáticas Regulares (Tipo 3)

Las más simples, reconocidas por autómatas finitos.

**Ejemplo: Números enteros**
```
G = ({S, D}, {0,1,2,...,9}, P, S)
P: S → D | DS
   D → 0|1|2|3|4|5|6|7|8|9
```

**Implementación en código:**
```python
# Reconocedor de números enteros
def is_integer(s):
    if not s:
        return False
    for char in s:
        if not char.isdigit():
            return False
    return True

# Pruebas
print(is_integer("123"))    # True
print(is_integer("12a3"))   # False
print(is_integer(""))       # False
```

### 2. Gramáticas Libres de Contexto (Tipo 2)

Usadas para la sintaxis de lenguajes de programación.

**Ejemplo: Expresiones aritméticas**
```
E → E + T | E - T | T
T → T * F | T / F | F
F → ( E ) | número
```

**Implementación de un parser simple:**
```tempo
// Parser de expresiones en Tempo
type TokenType = enum {
    NUMBER,
    PLUS,
    MINUS,
    MULTIPLY,
    DIVIDE,
    LPAREN,
    RPAREN,
    EOF
}

type Token = struct {
    type: TokenType,
    value: string
}

// Parseador recursivo descendente
function parse_expression(tokens: []Token, pos: &i32) -> i32 {
    let left = parse_term(tokens, pos);
    
    while (pos < tokens.length) {
        if (tokens[pos].type == PLUS) {
            pos += 1;
            let right = parse_term(tokens, pos);
            left = left + right;
        } else if (tokens[pos].type == MINUS) {
            pos += 1;
            let right = parse_term(tokens, pos);
            left = left - right;
        } else {
            break;
        }
    }
    
    return left;
}

function parse_term(tokens: []Token, pos: &i32) -> i32 {
    let left = parse_factor(tokens, pos);
    
    while (pos < tokens.length) {
        if (tokens[pos].type == MULTIPLY) {
            pos += 1;
            let right = parse_factor(tokens, pos);
            left = left * right;
        } else if (tokens[pos].type == DIVIDE) {
            pos += 1;
            let right = parse_factor(tokens, pos);
            left = left / right;
        } else {
            break;
        }
    }
    
    return left;
}

function parse_factor(tokens: []Token, pos: &i32) -> i32 {
    if (tokens[pos].type == NUMBER) {
        let value = string_to_int(tokens[pos].value);
        pos += 1;
        return value;
    } else if (tokens[pos].type == LPAREN) {
        pos += 1;  // Saltar '('
        let result = parse_expression(tokens, pos);
        pos += 1;  // Saltar ')'
        return result;
    }
    
    panic("Error de sintaxis");
}
```

### 3. Diseñando la gramática de Tempo

Veamos parte de la gramática real de Tempo:

```
// Programa
program → declaration*

// Declaraciones
declaration → function_decl | struct_decl | const_decl

// Funciones con garantías de tiempo
function_decl → "function" IDENTIFIER "(" params? ")" 
                ("->" type)? ("within" time_bound)? block

time_bound → constant time_unit | "O(" complexity ")"
time_unit → "ns" | "µs" | "ms" | "s"
complexity → "1" | "log n" | "n" | "n log n" | "n²"

// Tipos
type → primitive_type | array_type | struct_type | pointer_type
primitive_type → "i8" | "i16" | "i32" | "i64" | "f32" | "f64" | "bool"
array_type → type "[" expression "]"

// Expresiones
expression → assignment
assignment → logical_or ("=" assignment)?
logical_or → logical_and ("||" logical_and)*
logical_and → equality ("&&" equality)*
equality → comparison (("==" | "!=") comparison)*
comparison → addition (("<" | ">" | "<=" | ">=") addition)*
addition → multiplication (("+" | "-") multiplication)*
multiplication → unary (("*" | "/" | "%") unary)*
unary → ("!" | "-" | "&" | "*") unary | postfix
postfix → primary ("[" expression "]" | "." IDENTIFIER | "(" args? ")")*
primary → NUMBER | STRING | "true" | "false" | IDENTIFIER | "(" expression ")"
```

### 4. Validador de gramática para Tempo

```tempo
// Validador simple de sintaxis Tempo
type GrammarRule = struct {
    name: string,
    patterns: []string
}

function validate_tempo_syntax(code: string) -> bool {
    // Reglas básicas
    let rules: []GrammarRule = [
        { name: "function", patterns: ["function [a-zA-Z_][a-zA-Z0-9_]* \\(.*\\) \\{"] },
        { name: "if", patterns: ["if \\(.*\\) \\{"] },
        { name: "let", patterns: ["let [a-zA-Z_][a-zA-Z0-9_]* = .*;" }] 
    ];
    
    // Verificar balance de paréntesis y llaves
    let paren_count = 0;
    let brace_count = 0;
    
    for (char in code) {
        match char {
            '(' => paren_count += 1,
            ')' => paren_count -= 1,
            '{' => brace_count += 1,
            '}' => brace_count -= 1,
            _ => {}
        }
        
        // No puede ser negativo
        if (paren_count < 0 || brace_count < 0) {
            return false;
        }
    }
    
    // Debe estar balanceado
    return paren_count == 0 && brace_count == 0;
}
```

### 5. Generador de gramáticas

```tempo
// Generador de cadenas a partir de una gramática
function generate_from_grammar(rules: map<string, []string>, 
                             start: string, 
                             max_depth: i32) -> string {
    if (max_depth <= 0) {
        return "";
    }
    
    let productions = rules[start];
    if (!productions) {
        return start;  // Es terminal
    }
    
    // Elegir una producción aleatoria (determinística con seed)
    let production = productions[0];  // Por simplicidad
    let result = "";
    
    // Expandir cada símbolo
    for (symbol in split_production(production)) {
        if (is_nonterminal(symbol)) {
            result += generate_from_grammar(rules, symbol, max_depth - 1);
        } else {
            result += symbol + " ";
        }
    }
    
    return result;
}

// Ejemplo de uso
function example_grammar() {
    let expr_grammar: map<string, []string> = {
        "E": ["E + T", "T"],
        "T": ["T * F", "F"],
        "F": ["( E )", "num"]
    };
    
    // Genera: "num + num * num"
    let expression = generate_from_grammar(expr_grammar, "E", 5);
    print(expression);
}
```

### 6. Analizador de ambigüedad

```tempo
// Detectar ambigüedad en gramáticas
function is_ambiguous(grammar: Grammar, test_string: string) -> bool {
    // Una gramática es ambigua si hay múltiples árboles de derivación
    let parse_trees = find_all_derivations(grammar, test_string);
    return parse_trees.length > 1;
}

// Ejemplo clásico: if-else colgante
function dangling_else_example() {
    // Gramática ambigua
    let ambiguous = {
        "S": ["if E then S", "if E then S else S", "other"],
        "E": ["expr"]
    };
    
    // La cadena "if E then if E then S else S" tiene 2 interpretaciones:
    // 1. if E then (if E then S else S)
    // 2. if E then (if E then S) else S
    
    // Gramática no ambigua (solución)
    let unambiguous = {
        "S": ["matched", "unmatched"],
        "matched": ["if E then matched else matched", "other"],
        "unmatched": ["if E then S", "if E then matched else unmatched"]
    };
}
```

## 🏋️ Ejercicios (20%)

### Ejercicio 1: Diseña una gramática
Crea una gramática formal para:
1. Direcciones IPv4 (ej: 192.168.1.1)
2. Identificadores de Tempo (empiezan con letra, pueden tener números y _)
3. Comentarios de Tempo (// para línea, /* */ para bloque)

### Ejercicio 2: Clasificación de lenguajes
Clasifica estos lenguajes según la jerarquía de Chomsky:
1. L = {aⁿbⁿ | n ≥ 0}  (mismo número de a's y b's)
2. L = {w | w tiene igual número de 0's y 1's}
3. L = {aⁿbⁿcⁿ | n ≥ 0}
4. L = {w | w es un palíndromo}

### Ejercicio 3: Parser de calculadora
Implementa un parser completo para expresiones con:
- Operadores: +, -, *, /, ^
- Paréntesis
- Números negativos
- Variables

### Ejercicio 4: Detección de ambigüedad
Determina si estas gramáticas son ambiguas:
```
G1: E → E + E | E * E | id
G2: E → T + E | T
    T → F * T | F
    F → id | (E)
```

### Ejercicio 5: Gramática para Tempo
Diseña reglas gramaticales para estas características de Tempo:
1. Declaración de arrays con tamaño fijo: `let arr: i32[10]`
2. Pattern matching: `match x { 0 => "zero", _ => "other" }`
3. Garantías de tiempo: `function sort(arr: []i32) within O(n log n)`

## 📚 Para profundizar

1. **Libro recomendado**: "Introduction to Automata Theory" - Hopcroft & Ullman
2. **Paper**: "On Certain Formal Properties of Grammars" - Noam Chomsky (1959)
3. **Herramienta**: ANTLR4 - Generador de parsers

## 💡 Dato curioso

La jerarquía de Chomsky fue desarrollada en 1956 por Noam Chomsky mientras estudiaba lenguaje natural. ¡Resultó ser fundamental para los lenguajes de programación! Fun fact: ningún lenguaje de programación real es completamente libre de contexto debido a las declaraciones de variables.

---

**Resumen**: Los lenguajes formales y las gramáticas son la base matemática de los compiladores. La jerarquía de Chomsky nos ayuda a clasificar qué tan complejo es parsear un lenguaje. Tempo usa una gramática cuidadosamente diseñada para ser no ambigua y fácil de parsear.

[← Lección 1](leccion1-intro.md) | [Índice](../README.md) | [Lección 3: Autómatas →](leccion3-automatas.md)