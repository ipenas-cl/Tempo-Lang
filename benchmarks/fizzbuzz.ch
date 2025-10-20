fn main() -> i32 {
    let i = 1;
    while (i <= 100) {
        let d3 = i / 3;
        let m3 = i - d3 * 3;
        let d5 = i / 5;
        let m5 = i - d5 * 5;
        
        if (m3 == 0) {
            if (m5 == 0) {
                println("FizzBuzz");
            } else {
                println("Fizz");
            }
        } else {
            if (m5 == 0) {
                println("Buzz");
            } else {
                print_int(i);
                println("");
            }
        }
        
        i = i + 1;
    }
    return 0;
}
