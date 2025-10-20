#include <stdio.h>

int is_prime(int n) {
    if (n <= 1) return 0;
    if (n <= 3) return 1;
    for (int i = 2; i * i <= n; i++) {
        if (n % i == 0) return 0;
    }
    return 1;
}

int main() {
    int count = 0;
    for (int n = 2; n <= 100; n++) {
        if (is_prime(n)) count++;
    }
    printf("Primes up to 100: %d\n", count);
    return 0;
}
