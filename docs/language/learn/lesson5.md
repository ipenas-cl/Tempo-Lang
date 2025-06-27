# Lesson 5: Building Your First Real Program

Time to put everything together and build a complete calculator application!

## What You'll Learn

- Planning a complete program
- Handling errors gracefully
- Creating a user-friendly interface
- Organizing code effectively

## Planning Our Calculator

Before coding, let's plan what our calculator will do:

1. Display a welcome message
2. Show available operations
3. Get numbers from the user (simulated)
4. Perform calculations
5. Handle errors (like division by zero)
6. Allow multiple calculations

## The Complete Calculator Program

```tempo
// Calculator functions
fn add(a: f64, b: f64) -> f64 {
    return a + b;
}

fn subtract(a: f64, b: f64) -> f64 {
    return a - b;
}

fn multiply(a: f64, b: f64) -> f64 {
    return a * b;
}

fn divide(a: f64, b: f64) -> f64 {
    if b == 0.0 {
        print_line("Error: Cannot divide by zero!");
        return 0.0;
    }
    return a / b;
}

fn power(base: f64, exponent: i32) -> f64 {
    let result = 1.0;
    for i in 0..exponent {
        result = result * base;
    }
    return result;
}

// Display functions
fn show_welcome() {
    print_line("╔════════════════════════════╗");
    print_line("║   TEMPO CALCULATOR v1.0    ║");
    print_line("╚════════════════════════════╝");
    print_line("");
}

fn show_menu() {
    print_line("Available operations:");
    print_line("  [1] Addition (+)");
    print_line("  [2] Subtraction (-)");
    print_line("  [3] Multiplication (×)");
    print_line("  [4] Division (÷)");
    print_line("  [5] Power (^)");
    print_line("  [6] Exit");
    print_line("");
}

fn show_result(operation: string, a: f64, b: f64, result: f64) {
    print_line("═══════════════════════════");
    print_line("Calculation:");
    print_line("  " + float_to_string(a) + " " + operation + " " + 
               float_to_string(b) + " = " + float_to_string(result));
    print_line("═══════════════════════════");
    print_line("");
}

// Helper function to convert float to string with 2 decimals
fn float_to_string(f: f64) -> string {
    let whole = f as i32;
    let decimal = ((f - whole as f64) * 100.0) as i32;
    
    if decimal == 0 {
        return int_to_string(whole);
    }
    
    return int_to_string(whole) + "." + int_to_string(decimal);
}

// Process user choice
fn perform_calculation(choice: i32, num1: f64, num2: f64) {
    let result = 0.0;
    let op_symbol = "";
    
    if choice == 1 {
        result = add(num1, num2);
        op_symbol = "+";
    } else if choice == 2 {
        result = subtract(num1, num2);
        op_symbol = "-";
    } else if choice == 3 {
        result = multiply(num1, num2);
        op_symbol = "×";
    } else if choice == 4 {
        result = divide(num1, num2);
        op_symbol = "÷";
    } else if choice == 5 {
        result = power(num1, num2 as i32);
        op_symbol = "^";
    } else {
        print_line("Invalid choice!");
        return;
    }
    
    show_result(op_symbol, num1, num2, result);
}

// Main program
fn main() -> i32 {
    show_welcome();
    
    // Simulate a session with multiple calculations
    let calculations = [
        [1, 10.5, 20.3],   // Add 10.5 + 20.3
        [2, 50.0, 15.0],   // Subtract 50 - 15
        [3, 7.0, 8.0],     // Multiply 7 × 8
        [4, 100.0, 0.0],   // Divide by zero (error case)
        [4, 100.0, 4.0],   // Divide 100 ÷ 4
        [5, 2.0, 8.0]      // Power 2^8
    ];
    
    for i in 0..6 {
        let choice = calculations[i][0] as i32;
        let num1 = calculations[i][1];
        let num2 = calculations[i][2];
        
        print_line("Calculation " + int_to_string(i + 1) + ":");
        perform_calculation(choice, num1, num2);
    }
    
    print_line("Thank you for using Tempo Calculator!");
    return 0;
}
```

## Key Concepts in This Program

### 1. Error Handling
```tempo
fn divide(a: f64, b: f64) -> f64 {
    if b == 0.0 {
        print_line("Error: Cannot divide by zero!");
        return 0.0;
    }
    return a / b;
}
```

### 2. Type Conversion
```tempo
let whole = f as i32;  // Convert float to integer
let decimal = ((f - whole as f64) * 100.0) as i32;
```

### 3. String Building
```tempo
print_line("  " + float_to_string(a) + " " + operation + " " + 
           float_to_string(b) + " = " + float_to_string(result));
```

### 4. Program Organization
- Functions grouped by purpose
- Clear naming conventions
- Separation of concerns

## Extending the Calculator

Here are some features you could add:

### 1. Square Root Function
```tempo
fn square_root(n: f64) -> f64 {
    // Simple approximation using Newton's method
    let guess = n / 2.0;
    for i in 0..10 {
        guess = (guess + n / guess) / 2.0;
    }
    return guess;
}
```

### 2. Memory Functions
```tempo
let memory = 0.0;

fn memory_store(value: f64) {
    memory = value;
    print_line("Stored: " + float_to_string(memory));
}

fn memory_recall() -> f64 {
    print_line("Recalled: " + float_to_string(memory));
    return memory;
}

fn memory_clear() {
    memory = 0.0;
    print_line("Memory cleared");
}
```

### 3. History Tracking
```tempo
fn main() -> i32 {
    let history = ["", "", "", "", ""];
    let history_count = 0;
    
    // After each calculation
    history[history_count] = float_to_string(num1) + " " + 
                            op_symbol + " " + 
                            float_to_string(num2) + " = " + 
                            float_to_string(result);
    history_count = history_count + 1;
    
    // Show history
    print_line("Calculation History:");
    for i in 0..history_count {
        print_line("  " + history[i]);
    }
    
    return 0;
}
```

## Best Practices Demonstrated

1. **Clear Function Names**: `add()`, `subtract()`, etc.
2. **Error Messages**: Helpful feedback for users
3. **Visual Separation**: Using lines and spacing
4. **Consistent Style**: Similar structure for all operations
5. **Comments**: Explaining major sections

## Debugging Tips

When your program doesn't work as expected:

1. **Add Print Statements**:
   ```tempo
   print_line("DEBUG: choice = " + int_to_string(choice));
   print_line("DEBUG: num1 = " + float_to_string(num1));
   ```

2. **Check Your Logic**:
   - Are your conditions correct?
   - Do your loops terminate?
   - Are you handling all cases?

3. **Test Edge Cases**:
   - Division by zero
   - Negative numbers
   - Very large numbers

## Your Final Challenge

Create an enhanced calculator that includes:

1. **Scientific Functions**:
   - Factorial (n!)
   - Percentage calculations
   - Average of multiple numbers

2. **Better Error Handling**:
   - Check for overflow
   - Validate all inputs
   - Provide helpful error messages

3. **Unit Conversion**:
   - Temperature (C ↔ F)
   - Length (meters ↔ feet)
   - Weight (kg ↔ pounds)

4. **Financial Calculator Mode**:
   - Simple interest calculation
   - Loan payment calculator
   - Currency conversion

## What You've Learned

Congratulations! You've now learned:
- ✅ Variables and data types
- ✅ Control flow (if/else)
- ✅ Loops and arrays
- ✅ Functions and parameters
- ✅ String manipulation
- ✅ Error handling
- ✅ Program organization

## Next Steps

You're ready to:
1. Explore more advanced Tempo features
2. Build your own projects
3. Contribute to the Tempo community
4. Learn about systems programming

Check out:
- [Tempo Language Reference](../tempcore_manual.md)
- [Example Projects](../../examples/)
- [Community Forum](https://github.com/ipenas-cl/Tempo-Lang/discussions)

---

**Final Challenge**: Build a "Personal Finance Tracker" that:
- Tracks income and expenses
- Categorizes transactions
- Calculates totals and balances
- Shows a summary report
- Saves data (simulate with arrays)

Remember: The best way to learn programming is by building things. Start small, experiment, and have fun!