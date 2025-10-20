fn is_prime(n: i32) -> i32 {
    if (n <= 1) {
        return 0;
    }
    if (n <= 3) {
        return 1;
    }
    
    let i = 2;
    while (i * i <= n) {
        let div = n / i;
        let mod = n - div * i;
        if (mod == 0) {
            return 0;
        }
        i = i + 1;
    }
    return 1;
}

fn main() -> i32 {
    let count = 0;
    let n = 2;
    while (n <= 100) {
        if (is_prime(n) == 1) {
            count = count + 1;
        }
        n = n + 1;
    }
    print("Primes up to 100: ");
    print_int(count);
    println("");
    return 0;
}
