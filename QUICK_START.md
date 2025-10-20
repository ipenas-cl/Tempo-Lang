# Chronos Quick Start Guide

Get started with Chronos in 5 minutes.

---

## 1. Install Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get install nasm gcc
```

**Fedora/RHEL:**
```bash
sudo dnf install nasm gcc
```

**Arch Linux:**
```bash
sudo pacman -S nasm gcc
```

---

## 2. Clone and Build

```bash
# Clone the repository
git clone https://github.com/ipenas-cl/Chronos.git
cd Chronos

# Build the bootstrap compiler
cd compiler/bootstrap-c
gcc chronos_v10.c -o chronos_v10
cd ../..
```

---

## 3. Your First Program

Create `hello.ch`:

```chronos
fn main() -> i32 {
    println("Hello, Chronos!");
    return 0;
}
```

---

## 4. Compile and Run

```bash
# Compile to assembly
./compiler/bootstrap-c/chronos_v10 hello.ch

# Assemble to object file
nasm -f elf64 output.asm -o output.o

# Link to executable
ld output.o -o hello

# Run!
./hello
```

**Output:**
```
Hello, Chronos!
```

---

## 5. More Examples

### Variables and Arithmetic

```chronos
fn main() -> i32 {
    let x = 10;
    let y = 20;
    let sum = x + y;

    print("Sum: ");
    print_int(sum);
    println("");

    return sum;
}
```

### Loops and Conditionals

```chronos
fn main() -> i32 {
    let i = 1;

    while (i <= 10) {
        if (i % 2 == 0) {
            print_int(i);
            println(" is even");
        }
        i = i + 1;
    }

    return 0;
}
```

### Functions and Recursion

```chronos
fn factorial(n: i32) -> i32 {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

fn main() -> i32 {
    let result = factorial(5);
    print("5! = ");
    print_int(result);
    println("");
    return result;
}
```

### Arrays

```chronos
fn main() -> i32 {
    let numbers: [i32; 5];
    numbers[0] = 10;
    numbers[1] = 20;
    numbers[2] = 30;
    numbers[3] = 40;
    numbers[4] = 50;

    let i = 0;
    while (i < 5) {
        print_int(numbers[i]);
        println("");
        i = i + 1;
    }

    return 0;
}
```

### Structs

```chronos
struct Point {
    x: i32,
    y: i32
}

fn main() -> i32 {
    let p: Point;
    p.x = 100;
    p.y = 200;

    print("Point: (");
    print_int(p.x);
    print(", ");
    print_int(p.y);
    println(")");

    return 0;
}
```

---

## 6. Run Tests

Test that everything works:

```bash
./scripts/run_tests.sh
```

Should see: **26/28 tests passing (93%)**

---

## 7. Explore Examples

Check out the `examples/` directory:

```bash
# FizzBuzz
./compiler/bootstrap-c/chronos_v10 examples/fizzbuzz.ch
nasm -f elf64 output.asm -o output.o
ld output.o -o fizzbuzz
./fizzbuzz

# Prime numbers
./compiler/bootstrap-c/chronos_v10 examples/primes.ch
nasm -f elf64 output.asm -o output.o
ld output.o -o primes
./primes

# Fibonacci
./compiler/bootstrap-c/chronos_v10 examples/fibonacci.ch
nasm -f elf64 output.asm -o output.o
ld output.o -o fibonacci
./fibonacci
```

---

## 8. Compile Script (Optional)

Create a helper script `compile.sh`:

```bash
#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Usage: ./compile.sh program.ch"
    exit 1
fi

INPUT=$1
OUTPUT=${INPUT%.ch}

./compiler/bootstrap-c/chronos_v10 "$INPUT" && \
nasm -f elf64 output.asm -o output.o && \
ld output.o -o "$OUTPUT" && \
echo "✅ Compiled: $OUTPUT"
```

Make it executable:
```bash
chmod +x compile.sh
```

Now you can just run:
```bash
./compile.sh hello.ch
./hello
```

---

## Next Steps

- **Read the docs**: [docs/FEATURES.md](docs/FEATURES.md)
- **See the changelog**: [CHANGELOG.md](CHANGELOG.md)
- **Check benchmarks**: [benchmarks/BENCHMARK_REPORT.md](benchmarks/BENCHMARK_REPORT.md)
- **Learn compiler internals**: [docs/language/course/](docs/language/course/)

---

## Common Issues

### "nasm: command not found"

Install NASM: `sudo apt-get install nasm`

### "ld: cannot find output.o"

Make sure compilation succeeded. Check for error messages.

### "Permission denied" when running

Make the file executable: `chmod +x program`

### Tests failing

Only 2 tests are expected to fail currently. If more fail, check that NASM is installed.

---

**Author**: Ignacio Peña
**License**: MIT
**Repository**: https://github.com/ipenas-cl/Chronos
