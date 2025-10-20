fn main() -> i32 {
    let sum = 0;
    let i = 1;
    while (i <= 1000000) {
        sum = sum + i;
        i = i + 1;
    }
    print_int(sum);
    println("");
    return 0;
}
