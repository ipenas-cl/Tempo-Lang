// Ackermann function - computationally intensive recursion benchmark
fn ackermann(m: i32, n: i32) -> i32 {
    if (m == 0) {
        return n + 1;
    }
    if (n == 0) {
        return ackermann(m - 1, 1);
    }
    return ackermann(m - 1, ackermann(m, n - 1));
}

fn main() -> i32 {
    return ackermann(3, 6);
}
