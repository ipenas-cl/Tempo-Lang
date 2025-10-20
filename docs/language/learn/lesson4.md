# Lesson 4: Functions and Text

Let's learn how to create reusable code and work with text!

## What You'll Learn

- Creating your own functions
- Working with text (strings)
- Function parameters and return values
- Building modular programs

## Creating Functions

Functions are reusable pieces of code:

```tempo
fn greet() {
    print_line("Hello!");
    print_line("Welcome to my program!");
}

fn main() -> i32 {
    greet();  // Call the function
    greet();  // Call it again
    return 0;
}
```

## Functions with Parameters

Pass information to functions:

```tempo
fn greet_person(name: string) {
    print_line("Hello, " + name + "!");
}

fn main() -> i32 {
    greet_person("Alice");
    greet_person("Bob");
    greet_person("Carlos");
    return 0;
}
```

## Functions that Return Values

Functions can calculate and return results:

```tempo
fn add(a: i32, b: i32) -> i32 {
    return a + b;
}

fn multiply(x: i32, y: i32) -> i32 {
    return x * y;
}

fn main() -> i32 {
    let sum = add(5, 3);
    print_line("5 + 3 = " + int_to_string(sum));
    
    let product = multiply(4, 7);
    print_line("4 × 7 = " + int_to_string(product));
    
    return 0;
}
```

## Working with Strings

Chronos has many built-in string functions:

```tempo
fn main() -> i32 {
    let message = "Hello, World!";
    
    // Get string length
    let len = string_length(message);
    print_line("Length: " + int_to_string(len));
    
    // Convert to uppercase/lowercase
    print_line("Upper: " + to_uppercase(message));
    print_line("Lower: " + to_lowercase(message));
    
    // Check if string contains text
    if string_contains(message, "World") {
        print_line("Found 'World' in the message!");
    }
    
    // Extract part of string
    let first_word = string_substring(message, 0, 5);
    print_line("First word: " + first_word);
    
    return 0;
}
```

## Practical String Functions

```tempo
fn is_valid_email(email: string) -> bool {
    // Simple email validation
    return string_contains(email, "@") && 
           string_contains(email, ".");
}

fn capitalize_name(name: string) -> string {
    // Make first letter uppercase
    let first = string_substring(name, 0, 1);
    let rest = string_substring(name, 1, string_length(name));
    return to_uppercase(first) + to_lowercase(rest);
}

fn main() -> i32 {
    // Test email validation
    let email1 = "user@example.com";
    let email2 = "invalid-email";
    
    if is_valid_email(email1) {
        print_line(email1 + " is valid");
    }
    
    if !is_valid_email(email2) {
        print_line(email2 + " is not valid");
    }
    
    // Test name capitalization
    let name = "jOHN";
    print_line("Original: " + name);
    print_line("Fixed: " + capitalize_name(name));
    
    return 0;
}
```

## Building a Text Menu

Let's combine everything to build an interactive menu:

```tempo
fn show_menu() {
    print_line("=== Calculator Menu ===");
    print_line("1. Add numbers");
    print_line("2. Subtract numbers");
    print_line("3. Multiply numbers");
    print_line("4. Exit");
    print_line("====================");
}

fn calculate(operation: string, a: i32, b: i32) -> i32 {
    if operation == "add" {
        return a + b;
    } else if operation == "subtract" {
        return a - b;
    } else if operation == "multiply" {
        return a * b;
    }
    return 0;
}

fn main() -> i32 {
    let choice = 1;  // Simulating user choice
    let num1 = 10;
    let num2 = 5;
    
    show_menu();
    print_line("You chose: " + int_to_string(choice));
    
    let result = 0;
    if choice == 1 {
        result = calculate("add", num1, num2);
        print_line("Result: " + int_to_string(result));
    } else if choice == 2 {
        result = calculate("subtract", num1, num2);
        print_line("Result: " + int_to_string(result));
    } else if choice == 3 {
        result = calculate("multiply", num1, num2);
        print_line("Result: " + int_to_string(result));
    }
    
    return 0;
}
```

## Function Best Practices

1. **Single Responsibility**: Each function should do one thing well
2. **Good Names**: Use descriptive names that explain what the function does
3. **Keep it Short**: Functions should be easy to read (usually < 20 lines)
4. **Document Complex Functions**: Add comments for tricky logic

```tempo
// Calculates the area of a circle given its radius
// Formula: π × r²
fn circle_area(radius: f64) -> f64 {
    let pi = 3.14159;
    return pi * radius * radius;
}
```

## Complete Example: Password Validator

```tempo
fn has_uppercase(text: string) -> bool {
    return text != to_lowercase(text);
}

fn has_number(text: string) -> bool {
    let numbers = "0123456789";
    for i in 0..string_length(text) {
        let char = string_substring(text, i, i+1);
        if string_contains(numbers, char) {
            return true;
        }
    }
    return false;
}

fn validate_password(password: string) -> bool {
    // Check length
    if string_length(password) < 8 {
        print_line("❌ Password must be at least 8 characters");
        return false;
    }
    
    // Check for uppercase
    if !has_uppercase(password) {
        print_line("❌ Password must contain uppercase letters");
        return false;
    }
    
    // Check for numbers
    if !has_number(password) {
        print_line("❌ Password must contain numbers");
        return false;
    }
    
    print_line("✅ Password is strong!");
    return true;
}

fn main() -> i32 {
    let passwords = ["weak", "StrongPass123", "NoNumbers", "12345678"];
    
    for i in 0..4 {
        print_line("\nChecking: " + passwords[i]);
        validate_password(passwords[i]);
    }
    
    return 0;
}
```

## Try It Yourself

1. **Temperature Converter Functions**: Create functions to:
   - Convert Celsius to Fahrenheit
   - Convert Fahrenheit to Celsius
   - Display both conversions for a temperature

2. **Text Analyzer**: Write a program that:
   - Counts words in a sentence (hint: count spaces + 1)
   - Finds the longest word
   - Reverses the text

3. **Simple Encryption**: Create functions that:
   - Shift each letter by 1 (A→B, B→C, etc.)
   - Decrypt by shifting back
   - Test with a secret message

## Common Mistakes

1. **Forgetting to return a value**
   ```tempo
   fn add(a: i32, b: i32) -> i32 {
       let sum = a + b;
       // Forgot return!
   }
   ```

2. **Wrong parameter types**
   ```tempo
   fn greet(name: string) {
       print_line("Hello, " + name);
   }
   
   greet(123);  // Wrong! Must pass a string
   ```

3. **Using variables from other functions**
   ```tempo
   fn func1() {
       let x = 10;
   }
   
   fn func2() {
       print_line(int_to_string(x));  // Wrong! x doesn't exist here
   }
   ```

## Next Lesson

In [Lesson 5](lesson5.md), you'll build your first complete program:
- A calculator with multiple operations
- Error handling
- A polished user experience

---

**Practice Challenge**: Create a "Text Adventure Game" that:
- Has functions for different rooms/locations
- Uses string functions to process commands
- Tracks player inventory in an array
- Has at least 3 locations and a winning condition