fn factorial(n: i32) -> i32 {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

fn main() -> i32 {
    return factorial(5);
}
