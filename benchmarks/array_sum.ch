// Array sum benchmark - memory access patterns
fn main() -> i32 {
    let arr: [i32; 1000];
    let i = 0;

    // Initialize array
    while (i < 1000) {
        arr[i] = i;
        i = i + 1;
    }

    // Sum array 100 times
    let sum = 0;
    let outer = 0;
    while (outer < 100) {
        i = 0;
        while (i < 1000) {
            sum = sum + arr[i];
            i = i + 1;
        }
        outer = outer + 1;
    }

    return sum % 1000;  // Return modulo to keep value small
}
