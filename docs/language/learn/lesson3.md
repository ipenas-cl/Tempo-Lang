# Lesson 3: Loops and Lists

Let's learn how to repeat actions and work with collections of data!

## What You'll Learn

- How to repeat code with loops
- Working with lists (arrays)
- Counting and iterating
- Building interactive programs

## While Loops: Repeat While True

A `while` loop repeats code as long as a condition is true:

```tempo
fn main() -> i32 {
    let count = 0;
    
    while count < 5 {
        print_line("Count: " + int_to_string(count));
        count = count + 1;
    }
    
    print_line("Done!");
    return 0;
}
```

Output:
```
Count: 0
Count: 1
Count: 2
Count: 3
Count: 4
Done!
```

## For Loops: Repeat a Specific Number of Times

For loops are perfect when you know how many times to repeat:

```tempo
fn main() -> i32 {
    // Count from 1 to 10
    for i in 1..11 {
        print_line(int_to_string(i));
    }
    
    // Count down from 10 to 1
    for i in 10..0 {
        print_line("T minus " + int_to_string(i));
    }
    print_line("Liftoff!");
    
    return 0;
}
```

## Working with Arrays

Arrays let you store multiple values:

```tempo
fn main() -> i32 {
    // Create an array of 5 numbers
    let scores = [85, 92, 78, 95, 88];
    
    // Access individual elements (starting at 0)
    print_line("First score: " + int_to_string(scores[0]));
    print_line("Last score: " + int_to_string(scores[4]));
    
    // Calculate average using a loop
    let total = 0;
    for i in 0..5 {
        total = total + scores[i];
    }
    let average = total / 5;
    print_line("Average: " + int_to_string(average));
    
    return 0;
}
```

## String Arrays

You can also have arrays of text:

```tempo
fn main() -> i32 {
    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];
    
    print_line("Work days:");
    for i in 0..5 {
        print_line("- " + days[i]);
    }
    
    return 0;
}
```

## Nested Loops

Loops inside loops create patterns:

```tempo
fn main() -> i32 {
    // Print a triangle of stars
    for i in 1..6 {
        let line = "";
        for j in 0..i {
            line = line + "*";
        }
        print_line(line);
    }
    
    return 0;
}
```

Output:
```
*
**
***
****
*****
```

## Breaking Out of Loops

Use `break` to exit early:

```tempo
fn main() -> i32 {
    let secret = 7;
    let guess = 0;
    
    while true {
        guess = guess + 1;
        print_line("Trying: " + int_to_string(guess));
        
        if guess == secret {
            print_line("Found it!");
            break;  // Exit the loop
        }
    }
    
    return 0;
}
```

## A Complete Example: Number Guessing Game

```tempo
fn main() -> i32 {
    let target = 42;
    let attempts = [50, 25, 37, 43, 41, 42];
    let found = false;
    
    print_line("Finding the number 42...");
    
    for i in 0..6 {
        let guess = attempts[i];
        print_line("Attempt " + int_to_string(i + 1) + ": " + int_to_string(guess));
        
        if guess == target {
            print_line("Found it!");
            found = true;
            break;
        } else if guess < target {
            print_line("Too low!");
        } else {
            print_line("Too high!");
        }
    }
    
    if !found {
        print_line("Number not found in attempts.");
    }
    
    return 0;
}
```

## Common Patterns

### Sum all numbers in an array:
```tempo
let numbers = [10, 20, 30, 40, 50];
let sum = 0;
for i in 0..5 {
    sum = sum + numbers[i];
}
```

### Find the largest number:
```tempo
let numbers = [45, 67, 23, 89, 12];
let max = numbers[0];
for i in 1..5 {
    if numbers[i] > max {
        max = numbers[i];
    }
}
```

### Count occurrences:
```tempo
let grades = ["A", "B", "A", "C", "A", "B"];
let count_a = 0;
for i in 0..6 {
    if grades[i] == "A" {
        count_a = count_a + 1;
    }
}
```

## Try It Yourself

1. **Multiplication Table**: Write a program that prints the multiplication table for 5 (5x1=5, 5x2=10, etc.)

2. **Temperature Converter**: Create an array of 7 temperatures in Celsius, convert each to Fahrenheit and print both

3. **Grade Report**: Given an array of test scores, calculate:
   - The average
   - The highest score
   - The lowest score
   - How many passed (score >= 60)

## Common Mistakes

1. **Off-by-one errors**
   ```tempo
   let arr = [1, 2, 3];
   for i in 0..4 {  // Wrong! Array only has 3 elements
       print_line(int_to_string(arr[i]));
   }
   ```

2. **Infinite loops**
   ```tempo
   let i = 0;
   while i < 10 {
       print_line("Hello");
       // Forgot to increment i!
   }
   ```

3. **Modifying the loop variable incorrectly**
   ```tempo
   for i in 0..5 {
       i = i + 2;  // Don't modify loop variable inside for loop
   }
   ```

## Next Lesson

In [Lesson 4](lesson4.md), you'll learn about:
- Creating your own functions
- Working with text (strings)
- Building reusable code

---

**Practice Challenge**: Create a "Class Statistics" program that:
- Has an array of 10 student test scores
- Calculates and displays the class average
- Shows how many students got A (90+), B (80-89), C (70-79), F (below 70)
- Identifies the highest and lowest scores