// Sieve of Eratosthenes - C version
#include <stdio.h>

int main() {
    int n = 1000;
    int primes[1000];
    int count = 0;

    // Initialize
    for (int i = 0; i < n; i++) {
        primes[i] = 1;
    }

    primes[0] = 0;
    primes[1] = 0;

    // Sieve
    for (int i = 2; i * i < n; i++) {
        if (primes[i]) {
            for (int j = i * i; j < n; j += i) {
                primes[j] = 0;
            }
        }
    }

    // Count
    for (int i = 0; i < n; i++) {
        if (primes[i]) count++;
    }

    return count;
}
