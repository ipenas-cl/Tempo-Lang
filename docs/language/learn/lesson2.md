# Lesson 2: Variables and Decisions

Now that you can print text, let's learn how to work with data and make decisions!

## What You'll Learn

- How to create and use variables
- Different types of data
- Making decisions with if/else
- Basic comparisons

## Variables: Storing Information

Variables are like labeled boxes where you store data:

```tempo
fn main() -> i32 {
    // Numbers
    let age = 30;
    let price = 19.99;
    
    // Text (strings)
    let name = "Maria";
    let city = "Santiago";
    
    // Yes/No values (booleans)
    let is_student = true;
    let has_discount = false;
    
    print_line("Name: " + name);
    print_line("Age: " + int_to_string(age));
    
    return 0;
}
```

## Making Decisions

Use `if` to make your program choose what to do:

```tempo
fn main() -> i32 {
    let age = 18;
    
    if age >= 18 {
        print_line("You can vote!");
    } else {
        print_line("Too young to vote.");
    }
    
    return 0;
}
```

## Comparison Operators

- `==` equal to
- `!=` not equal to
- `>` greater than
- `<` less than
- `>=` greater than or equal
- `<=` less than or equal

## Multiple Conditions

```tempo
fn main() -> i32 {
    let score = 85;
    
    if score >= 90 {
        print_line("Grade: A");
    } else if score >= 80 {
        print_line("Grade: B");
    } else if score >= 70 {
        print_line("Grade: C");
    } else {
        print_line("Grade: F");
    }
    
    return 0;
}
```

## Combining Conditions

Use `&&` (and) and `||` (or):

```tempo
fn main() -> i32 {
    let age = 25;
    let has_license = true;
    
    // Both conditions must be true
    if age >= 18 && has_license {
        print_line("You can drive!");
    }
    
    let is_weekend = true;
    let is_holiday = false;
    
    // At least one condition must be true
    if is_weekend || is_holiday {
        print_line("No work today!");
    }
    
    return 0;
}
```

## A Complete Example

Let's make a simple temperature converter:

```tempo
fn main() -> i32 {
    // Temperature in Celsius
    let celsius = 25;
    
    // Convert to Fahrenheit
    let fahrenheit = (celsius * 9 / 5) + 32;
    
    print_line("Temperature: " + int_to_string(celsius) + "°C");
    print_line("That's " + int_to_string(fahrenheit) + "°F");
    
    // Give advice based on temperature
    if celsius > 30 {
        print_line("It's hot! Drink water!");
    } else if celsius < 10 {
        print_line("It's cold! Wear a jacket!");
    } else {
        print_line("Nice weather!");
    }
    
    return 0;
}
```

## Variable Rules

1. Names must start with a letter
2. Can contain letters, numbers, and underscores
3. Case sensitive: `age` and `Age` are different
4. Choose meaningful names

Good names:
- `user_age`
- `total_price`
- `is_valid`

Bad names:
- `x`
- `data123`
- `temp`

## Try It Yourself

1. **Age Calculator**: Write a program that:
   - Sets your birth year
   - Calculates your age
   - Tells if you're a teenager (13-19)

2. **Store Discount**: Write a program that:
   - Has a price variable
   - Applies 20% discount if price > 100
   - Shows original and final price

3. **Grade Calculator**: Write a program that:
   - Has variables for 3 test scores
   - Calculates the average
   - Shows the letter grade

## Common Mistakes

1. **Using uninitialized variables**
   ```tempo
   let age;  // Wrong!
   print_line(int_to_string(age));
   ```

2. **Wrong types in comparisons**
   ```tempo
   let name = "Alice";
   if name > 10 {  // Wrong! Can't compare string to number
   ```

3. **Missing else in chains**
   ```tempo
   if score > 90 {
       print_line("A");
   } if score > 80 {  // Wrong! Should be 'else if'
       print_line("B");
   }
   ```

## Next Lesson

In [Lesson 3](lesson3.md), you'll learn about:
- Loops to repeat code
- Working with lists of data
- Building more complex programs

---

**Practice Challenge**: Create a "Movie Ticket Price Calculator" that:
- Has variables for age and day of week
- Charges $12 for adults, $8 for children (under 12)
- Gives 50% discount on Wednesdays
- Shows the final price