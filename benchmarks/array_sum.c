// Array sum benchmark - C version
int main() {
    int arr[1000];

    // Initialize
    for (int i = 0; i < 1000; i++) {
        arr[i] = i;
    }

    // Sum 100 times
    int sum = 0;
    for (int outer = 0; outer < 100; outer++) {
        for (int i = 0; i < 1000; i++) {
            sum += arr[i];
        }
    }

    return sum % 1000;
}
