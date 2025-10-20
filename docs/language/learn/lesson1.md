# Lesson 1: Your First Chronos Program

Welcome to programming with Chronos! In this lesson, you'll write and run your first program.

## What You'll Learn

- How to write a simple Chronos program
- How to compile and run it
- Basic syntax: functions and printing

## Your First Program

Create a file called `hello.tempo`:

```tempo
fn main() -> i32 {
    print_line("Hello! Welcome to Chronos!");
    print_line("This is my first program.");
    return 0;
}
```

## Understanding the Code

Let's break it down line by line:

1. `fn main() -> i32 {` - This creates the main function, where your program starts
   - `fn` means "function"
   - `main` is the name (every program needs a main function)
   - `-> i32` means it returns a number
   - `{` starts the function body

2. `print_line("Hello! Welcome to Chronos!");` - This prints text to the screen
   - `print_line` is a built-in function
   - Text goes inside quotes `""`

3. `return 0;` - This ends the program successfully
   - `0` means "everything went OK"

4. `}` - This ends the function

## Running Your Program

```bash
# Compile it
bin/tempo hello.tempo

# Run it
./stage1
```

You should see:
```
Hello! Welcome to Chronos!
This is my first program.
```

## Try It Yourself

1. Change the messages to say something different
2. Add more `print_line` statements
3. Try this program that uses variables:

```tempo
fn main() -> i32 {
    let name = "Alice";
    let age = 25;
    
    print_line("Hello, my name is:");
    print_line(name);
    print_line("I am this many years old:");
    print_line(int_to_string(age));
    
    return 0;
}
```

## What Makes Chronos Special?

Unlike other languages, Chronos:
- Doesn't need `import` statements - everything is ready to use
- Guarantees your program will always behave the same way
- Compiles to a small, fast binary

## Common Mistakes

1. **Forgetting semicolons** - Every statement needs a `;` at the end
2. **Wrong quotes** - Use `"` not `'` for text
3. **Missing return** - The main function must return a number

## Next Lesson

In [Lesson 2](lesson2.md), you'll learn about:
- Variables and types
- Basic math operations
- Getting input from the user

---

**Practice Challenge**: Write a program that prints your favorite quote, the author's name, and the year they said it.