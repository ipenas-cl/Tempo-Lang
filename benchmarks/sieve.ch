// Sieve of Eratosthenes - prime number calculation
fn main() -> i32 {
    let n = 1000;
    let primes: [i32; 1000];
    let count = 0;

    // Initialize all as potential primes
    let i = 0;
    while (i < n) {
        primes[i] = 1;
        i = i + 1;
    }

    // 0 and 1 are not primes
    primes[0] = 0;
    primes[1] = 0;

    // Sieve
    i = 2;
    while (i * i < n) {
        if (primes[i] == 1) {
            let j = i * i;
            while (j < n) {
                primes[j] = 0;
                j = j + i;
            }
        }
        i = i + 1;
    }

    // Count primes
    i = 0;
    while (i < n) {
        if (primes[i] == 1) {
            count = count + 1;
        }
        i = i + 1;
    }

    return count;
}
