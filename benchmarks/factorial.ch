fn factorial(n: i32) -> i32 {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

fn main() -> i32 {
    let i = 1;
    while (i <= 10) {
        print_int(i);
        print(" -> ");
        print_int(factorial(i));
        println("");
        i = i + 1;
    }
    return 0;
}
