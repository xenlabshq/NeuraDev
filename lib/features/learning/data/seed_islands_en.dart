import 'package:flutter/material.dart';

import 'package:neuroup/features/learning/domain/entities/learning_island.dart';

/// English content variant of [IslandSeed] — same island/node ids, order,
/// colors, emoji and points so progress (stored by id) carries over
/// seamlessly when the user switches the app language. Only the
/// display text and the Python code samples (translated consistently
/// with matching `expectedOutput`) differ.
class IslandSeedEn {
  IslandSeedEn._();

  static List<LearningIsland> all() => _islands;

  static final List<LearningIsland> _islands = [
    // ISLAND 1: Starter
    LearningIsland(
      id: 'island_intro',
      title: 'Starter Island',
      subtitle: 'print() and comments',
      description:
          "Learn Python's basic building blocks. Print your first message "
          'to the screen.',
      emoji: '🏝️',
      color: const Color(0xFF06B6D4),
      gradient: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
      order: 1,
      nodes: const [
        LearningNode(
          id: 'n_intro_1',
          title: 'First Hello',
          description: 'Print "Hello World" to the screen.',
          tutorial:
              '# The print() function writes text to the screen.\n# Text inside quotes is called a string.\n\nprint("Hello World")',
          starterCode: '# Print "Hello World" to the screen\n',
          solution: 'print("Hello World")',
          expectedOutput: 'Hello World',
          points: 50,
          emoji: '👋',
          order: 1,
          hints: [
            'Use print() to display text on the screen.',
            'Wrap the text you want to print in quotes: print("text")',
            'Write exactly: print("Hello World")',
          ],
        ),
        LearningNode(
          id: 'n_intro_2',
          title: 'Comment Lines',
          description: 'Comments explain code and are never executed.',
          tutorial:
              '# Comment lines start with #.\n# Python ignores comments — they are only for humans.\n\n# This is a comment\nprint("The code below a comment still runs")',
          starterCode: '# This line is a comment\nprint("This runs")',
          solution: '# This line is a comment\nprint("This runs")',
          expectedOutput: 'This runs',
          points: 60,
          emoji: '💬',
          order: 2,
          hints: [
            "Lines starting with # are comments — Python never executes them, they're only for humans.",
            'The print() line below the comment still runs normally.',
            "The code is already correct — just press Run, the comment doesn't affect the output.",
          ],
        ),
        LearningNode(
          id: 'n_intro_3',
          title: 'Multiple Prints',
          description: 'Print more than one line.',
          tutorial:
              '# Each print() starts a new line.\n# You can stack multiple print calls.\n\nprint("Line 1")\nprint("Line 2")\nprint("Line 3")',
          starterCode:
              'print("Name: Alex")\nprint("Age: 25")\nprint("City: London")',
          solution:
              'print("Name: Alex")\nprint("Age: 25")\nprint("City: London")',
          expectedOutput: 'Name: Alex\nAge: 25\nCity: London',
          points: 70,
          emoji: '📝',
          order: 3,
          hints: [
            'Every print() call starts a new line in the output.',
            'To show three separate pieces of information, use three separate print() lines.',
            "The code already has three print() calls — each one prints on its own line, in order.",
          ],
        ),
      ],
    ),

    // ISLAND 2: Variables
    LearningIsland(
      id: 'island_variables',
      title: 'Variables Island',
      subtitle: 'Store and name your data',
      description:
          'Variables hold data in memory. Name them, then use them.',
      emoji: '🏝️',
      color: const Color(0xFF8B5CF6),
      gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      order: 2,
      nodes: const [
        LearningNode(
          id: 'n_var_1',
          title: 'Your First Variable',
          description: 'Create a variable and print it.',
          tutorial:
              '# A variable is assigned a value with =.\n# name = "Alex"  →  the variable name holds "Alex".\n\nname = "Alex"\nprint(name)',
          starterCode: 'name = "Alex"\nprint(name)',
          solution: 'name = "Alex"\nprint(name)',
          expectedOutput: 'Alex',
          points: 80,
          emoji: '📦',
          order: 1,
          hints: [
            'Use = to assign a value to a variable: name = value',
            'String (text) values go inside quotes: name = "Alex"',
            'After name = "Alex", print it out with print(name).',
          ],
        ),
        LearningNode(
          id: 'n_var_2',
          title: 'Number Variables',
          description: 'Whole numbers and decimals.',
          tutorial:
              '# Numbers in Python are written without quotes.\n# int = whole number, float = decimal number\n\nage = 20\nheight = 1.75\nprint(age)\nprint(height)',
          starterCode:
              'number = 42\ndecimal = 3.14\nprint(number)\nprint(decimal)',
          solution:
              'number = 42\ndecimal = 3.14\nprint(number)\nprint(decimal)',
          expectedOutput: '42\n3.14',
          points: 90,
          emoji: '🔢',
          order: 2,
          hints: [
            'Numbers are written WITHOUT quotes, directly: age = 20',
            'A number with a decimal point is a float: height = 1.75',
            "Define both variables, then print each one with its own print().",
          ],
        ),
        LearningNode(
          id: 'n_var_3',
          title: 'Boolean (True/False)',
          description: 'The True and False values.',
          tutorial:
              '# The bool type only has two values: True or False.\n# In Python, True/False start with a capital letter.\n\nis_student = True\nis_graduate = False\nprint(is_student)\nprint(is_graduate)',
          starterCode:
              'active = True\ndeleted = False\nprint(active)\nprint(deleted)',
          solution:
              'active = True\ndeleted = False\nprint(active)\nprint(deleted)',
          expectedOutput: 'True\nFalse',
          points: 100,
          emoji: '✓',
          order: 3,
          hints: [
            'In Python, boolean values can only be True or False.',
            'True and False always start with a capital letter and are never quoted.',
            'Write active = True and deleted = False, then print both.',
          ],
        ),
        LearningNode(
          id: 'n_var_4',
          title: 'Combining Variables',
          description: 'Combine text and variables with an f-string.',
          tutorial:
              '# An f-string (f"...") lets you embed {{variable}} inside text.\n# It is the modern, easiest way.\n\nname = "Zoe"\nprint(f"Hello {name}!")',
          starterCode:
              'name = "Michael"\nage = 30\nprint(f"{name} is {age} years old")',
          solution:
              'name = "Michael"\nage = 30\nprint(f"{name} is {age} years old")',
          expectedOutput: 'Michael is 30 years old',
          points: 120,
          emoji: '🔗',
          order: 4,
          hints: [
            'An f-string starts with an f right before the quotes: f"..."',
            'Put a variable name inside curly braces {} to embed its value in the text: f"{name}"',
            'Use something like print(f"{name} is {age} years old").',
          ],
        ),
      ],
    ),

    // ISLAND 3: Operators
    LearningIsland(
      id: 'island_operators',
      title: 'Operators Island',
      subtitle: 'Math and comparisons',
      description: 'Do math with numbers and compare them.',
      emoji: '🏝️',
      color: const Color(0xFFF59E0B),
      gradient: const [Color(0xFFFBBF24), Color(0xFFF97316)],
      order: 3,
      nodes: const [
        LearningNode(
          id: 'n_op_1',
          title: 'Addition and Subtraction',
          description: 'The + and - operators.',
          tutorial:
              '# + adds, - subtracts.\n# You can print the result directly.\n\nprint(10 + 5)\nprint(20 - 8)',
          starterCode: 'print(15 + 7)\nprint(100 - 45)',
          solution: 'print(15 + 7)\nprint(100 - 45)',
          expectedOutput: '22\n55',
          points: 100,
          emoji: '➕',
          order: 1,
          hints: [
            '+ adds, - subtracts.',
            'You can put the calculation directly inside print(): print(15 + 7)',
            'Write print(15 + 7) and print(100 - 45).',
          ],
        ),
        LearningNode(
          id: 'n_op_2',
          title: 'Multiplication and Division',
          description: 'The * and / operators.',
          tutorial:
              '# * multiplies, / divides.\n# In Python, division always returns a decimal (float).\n\nprint(6 * 4)\nprint(20 / 5)',
          starterCode: 'print(7 * 8)\nprint(81 / 9)',
          solution: 'print(7 * 8)\nprint(81 / 9)',
          expectedOutput: '56\n9.0',
          points: 110,
          emoji: '✖',
          order: 2,
          hints: [
            '* multiplies, / divides.',
            'In Python, / ALWAYS returns a decimal (float) result, even when the numbers divide evenly.',
            'Write print(7 * 8) and print(81 / 9) — the second result will be 9.0, not 9.',
          ],
        ),
        LearningNode(
          id: 'n_op_3',
          title: 'Comparison',
          description: 'The <, >, == operators.',
          tutorial:
              '# Comparisons return True or False.\n# == means equal, != means not equal.\n\nprint(5 > 3)\nprint(10 == 10)\nprint(7 < 4)',
          starterCode: 'print(15 > 20)\nprint(8 == 8)\nprint(3 != 3)',
          solution: 'print(15 > 20)\nprint(8 == 8)\nprint(3 != 3)',
          expectedOutput: 'False\nTrue\nFalse',
          points: 130,
          emoji: '⚖',
          order: 3,
          hints: [
            'Comparison operators (>, <, ==) always return True or False.',
            "== checks equality (a single = is for assignment, don't mix them up).",
            'Write print(15 > 20), print(8 == 8), and print(3 != 3) in order.',
          ],
        ),
      ],
    ),

    // ISLAND 4: Conditionals
    LearningIsland(
      id: 'island_conditionals',
      title: 'Conditionals Island',
      subtitle: 'Learn to make decisions',
      description:
          'Use if/else to do different things based on conditions.',
      emoji: '🏝️',
      color: const Color(0xFFEF4444),
      gradient: const [Color(0xFFEF4444), Color(0xFFFB7185)],
      order: 4,
      nodes: const [
        LearningNode(
          id: 'n_if_1',
          title: 'Your First if',
          description: 'Run code only if a condition is true.',
          tutorial:
              '# The if condition: structure runs the code when the condition is True.\n# Indentation (4 spaces) matters a lot!\n\nage = 18\nif age >= 18:\n    print("You are an adult")',
          starterCode: 'number = 10\nif number > 5:\n    print("Big")',
          solution: 'number = 10\nif number > 5:\n    print("Big")',
          expectedOutput: 'Big',
          points: 140,
          emoji: '🔀',
          order: 1,
          hints: [
            'The line right after if condition: must be indented by 4 spaces.',
            "If the condition is True, the indented block runs; if False, it's skipped.",
            'if number > 5:\n    print("Big") — watch the indentation.',
          ],
        ),
        LearningNode(
          id: 'n_if_2',
          title: 'if-else',
          description: 'Do something else if the condition is false.',
          tutorial:
              '# else: runs when the condition is False.\n\nscore = 45\nif score >= 50:\n    print("Passed")\nelse:\n    print("Failed")',
          starterCode:
              'number = 3\nif number > 5:\n    print("Big")\nelse:\n    print("Small or equal")',
          solution:
              'number = 3\nif number > 5:\n    print("Big")\nelse:\n    print("Small or equal")',
          expectedOutput: 'Small or equal',
          points: 150,
          emoji: '↔',
          order: 2,
          hints: [
            'The else: block runs when the if condition is False.',
            "else doesn't take its own condition — just write else: on its own.",
            'if number > 5:\n    print("Big")\nelse:\n    print("Small or equal")',
          ],
        ),
        LearningNode(
          id: 'n_if_3',
          title: 'elif Chain',
          description: 'Check more than one condition.',
          tutorial:
              '# elif = "else if" — checks a new condition if the previous one was False.\n\nscore = 85\nif score >= 90:\n    print("A")\nelif score >= 80:\n    print("B")\nelif score >= 70:\n    print("C")\nelse:\n    print("F")',
          starterCode:
              'number = 0\nif number > 0:\n    print("Positive")\nelif number < 0:\n    print("Negative")\nelse:\n    print("Zero")',
          solution:
              'number = 0\nif number > 0:\n    print("Positive")\nelif number < 0:\n    print("Negative")\nelse:\n    print("Zero")',
          expectedOutput: 'Zero',
          points: 170,
          emoji: '🔗',
          order: 3,
          hints: [
            "elif means 'else if' — it checks a new condition only if the previous ones were False.",
            "The chain is checked top to bottom; once one condition is True, its block runs and the chain stops.",
            'if number > 0: ... elif number < 0: ... else: print("Zero") — since number is 0, the final else runs.',
          ],
        ),
      ],
    ),

    // ISLAND 5: Loops
    LearningIsland(
      id: 'island_loops',
      title: 'Loops Island',
      subtitle: 'Repeating tasks',
      description: 'Automate repeating tasks with for and while.',
      emoji: '🏝️',
      color: const Color(0xFF10B981),
      gradient: const [Color(0xFF10B981), Color(0xFF14B8A6)],
      order: 5,
      nodes: const [
        LearningNode(
          id: 'n_loop_1',
          title: 'Counting with for',
          description: 'Print 1 through 5 using range().',
          tutorial:
              '# for i in range(5): loops from 0 to 4.\n# range(1, 6) loops from 1 to 5.\n\nfor i in range(1, 6):\n    print(i)',
          starterCode: 'for i in range(1, 4):\n    print(i)',
          solution: 'for i in range(1, 4):\n    print(i)',
          expectedOutput: '1\n2\n3',
          points: 160,
          emoji: '🔁',
          order: 1,
          hints: [
            'for i in range(a, b): counts from a up to b-1 (b itself is not included).',
            "To count from 1 to 3, you need range(1, 4) — 4 isn't included, so it stops at 3.",
            'for i in range(1, 4):\n    print(i) — this prints 1, 2, 3.',
          ],
        ),
        LearningNode(
          id: 'n_loop_2',
          title: 'Looping over a List',
          description: 'Loop over a list.',
          tutorial:
              '# for item in list: runs the code once per item.\n\nfruits = ["apple", "pear", "banana"]\nfor fruit in fruits:\n    print(fruit)',
          starterCode:
              'colors = ["red", "blue", "green"]\nfor color in colors:\n    print(color)',
          solution:
              'colors = ["red", "blue", "green"]\nfor color in colors:\n    print(color)',
          expectedOutput: 'red\nblue\ngreen',
          points: 170,
          emoji: '🍎',
          order: 2,
          hints: [
            'for item in list: walks through every item in the list, one at a time.',
            'You can name the loop variable anything you like, as long as it matches inside the loop body.',
            'for color in colors:\n    print(color) — prints each color on its own line.',
          ],
        ),
        LearningNode(
          id: 'n_loop_3',
          title: 'The while Loop',
          description: 'Repeat as long as a condition is true.',
          tutorial:
              '# while condition: runs as long as the condition is True.\n# It is IMPORTANT to stop it eventually with a counter.\n\nnumber = 1\nwhile number <= 3:\n    print(number)\n    number = number + 1',
          starterCode:
              'number = 0\nwhile number < 3:\n    print(number)\n    number = number + 1',
          solution:
              'number = 0\nwhile number < 3:\n    print(number)\n    number = number + 1',
          expectedOutput: '0\n1\n2',
          points: 180,
          emoji: '⏳',
          order: 3,
          hints: [
            'while condition: keeps repeating as long as the condition stays True.',
            "Don't forget to update the counter variable inside the loop, or it will never stop.",
            'while number < 3:\n    print(number)\n    number = number + 1 — number increases by 1 each time.',
          ],
        ),
        LearningNode(
          id: 'n_loop_4',
          title: 'Multiplication Table',
          description: 'A multiplication table using nested loops.',
          tutorial:
              '# Nested loops: the outer loop is the row, the inner loop is the column.\n\nfor i in range(1, 4):\n    for j in range(1, 4):\n        print(f"{i}x{j}={i*j}")',
          starterCode:
              'for i in range(1, 3):\n    for j in range(1, 3):\n        print(f"{i}*{j}={i*j}")',
          solution:
              'for i in range(1, 3):\n    for j in range(1, 3):\n        print(f"{i}*{j}={i*j}")',
          expectedOutput: '1*1=1\n1*2=2\n2*1=2\n2*2=4',
          points: 200,
          emoji: '🧮',
          order: 4,
          hints: [
            'In a nested loop, the inner loop runs completely for every single step of the outer loop.',
            'The outer loop (i) represents the row, the inner loop (j) represents the column — the product is i*j.',
            'for i in range(1, 3):\n    for j in range(1, 3):\n        print(f"{i}*{j}={i*j}")',
          ],
        ),
      ],
    ),

    // ISLAND 6: Lists
    LearningIsland(
      id: 'island_lists',
      title: 'Lists Island',
      subtitle: 'Collections of data',
      description: 'Keep multiple values in one place: lists.',
      emoji: '🏝️',
      color: const Color(0xFFFBBF24),
      gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      order: 6,
      nodes: const [
        LearningNode(
          id: 'n_list_1',
          title: 'Defining a List',
          description: 'Create a list with square brackets.',
          tutorial:
              '# list = [item1, item2, ...]\n# A list can hold different types together.\n\nnumbers = [1, 2, 3, 4, 5]\nprint(numbers[0])  # First item (index 0)\nprint(numbers[-1]) # Last item',
          starterCode:
              'fruits = ["apple", "pear", "banana"]\nprint(fruits[0])\nprint(fruits[2])',
          solution:
              'fruits = ["apple", "pear", "banana"]\nprint(fruits[0])\nprint(fruits[2])',
          expectedOutput: 'apple\nbanana',
          points: 150,
          emoji: '📋',
          order: 1,
          hints: [
            'A list is created with square brackets [], with items separated by commas.',
            'Indexes start at 0 — list[0] is the first item, list[-1] is the last item.',
            "fruits[0] gives the first item ('apple'), fruits[2] gives the third ('banana').",
          ],
        ),
        LearningNode(
          id: 'n_list_2',
          title: 'Adding with append',
          description: 'Add a new item to a list.',
          tutorial:
              '# list.append(new_item) adds to the end.\n\nnumbers = [1, 2, 3]\nnumbers.append(4)\nprint(numbers)',
          starterCode: 'numbers = [10, 20]\nnumbers.append(30)\nprint(numbers)',
          solution: 'numbers = [10, 20]\nnumbers.append(30)\nprint(numbers)',
          expectedOutput: '[10, 20, 30]',
          points: 160,
          emoji: '➕',
          order: 2,
          hints: [
            'list.append(value) adds a new item to the END of the list.',
            'append() always adds to the end — it never inserts at the start or middle.',
            'After numbers.append(30), print(numbers) should show [10, 20, 30].',
          ],
        ),
        LearningNode(
          id: 'n_list_3',
          title: 'Length with len()',
          description: 'How many items does the list have?',
          tutorial:
              '# len(list) returns the length of the list.\n\nfruits = ["apple", "pear", "banana", "grape"]\nprint(len(fruits))',
          starterCode:
              'numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]\nprint(len(numbers))',
          solution:
              'numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]\nprint(len(numbers))',
          expectedOutput: '10',
          points: 150,
          emoji: '📏',
          order: 3,
          hints: [
            'The len(list) function returns how many items are in the list.',
            "len() is a standalone function — it's len(list), not list.len().",
            'print(len(numbers)) — a 10-item list gives 10.',
          ],
        ),
      ],
    ),

    // ISLAND 7: Functions
    LearningIsland(
      id: 'island_functions',
      title: 'Functions Island',
      subtitle: 'Package your code, reuse it',
      description:
          'Functions: write repeating code once, call it wherever you need it.',
      emoji: '🏝️',
      color: const Color(0xFFEC4899),
      gradient: const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
      order: 7,
      nodes: const [
        LearningNode(
          id: 'n_fn_1',
          title: 'Your First Function',
          description: 'Define a function with def.',
          tutorial:
              '# Defined with def function_name():\n# The body is indented by 4 spaces.\n\ndef greet():\n    print("Hello!")\n\ngreet()',
          starterCode: 'def greet():\n    print("Hi!")\n\ngreet()',
          solution: 'def greet():\n    print("Hi!")\n\ngreet()',
          expectedOutput: 'Hi!',
          points: 180,
          emoji: '⚙',
          order: 1,
          hints: [
            'def function_name(): defines a new function, and its body is indented.',
            'Defining a function does NOT run it — you have to CALL it with function_name().',
            'def greet():\n    print("Hi!")\n\ngreet() — the last line calls the function.',
          ],
        ),
        LearningNode(
          id: 'n_fn_2',
          title: 'Function with a Parameter',
          description: 'Pass a value into a function.',
          tutorial:
              '# def greet(name): takes a parameter.\n\ndef greet(name):\n    print(f"Hello {name}!")\n\ngreet("Alex")\ngreet("Amy")',
          starterCode:
              'def square(number):\n    print(number * number)\n\nsquare(5)\nsquare(7)',
          solution:
              'def square(number):\n    print(number * number)\n\nsquare(5)\nsquare(7)',
          expectedOutput: '25\n49',
          points: 190,
          emoji: '📨',
          order: 2,
          hints: [
            'A name inside the parentheses makes the function take a parameter: def square(number):',
            'When you call the function, you pass a real value inside the parentheses: square(5)',
            'def square(number):\n    print(number * number)\n\nsquare(5)\nsquare(7) — prints 25 then 49.',
          ],
        ),
        LearningNode(
          id: 'n_fn_3',
          title: 'Returning a Value with return',
          description: 'Have a function give back a result.',
          tutorial:
              '# return gives back a value, which can be stored in a variable.\n\ndef total(a, b):\n    return a + b\n\nresult = total(3, 5)\nprint(result)',
          starterCode:
              'def square(number):\n    return number * number\n\nprint(square(4))\nprint(square(9))',
          solution:
              'def square(number):\n    return number * number\n\nprint(square(4))\nprint(square(9))',
          expectedOutput: '16\n81',
          points: 200,
          emoji: '↩',
          order: 3,
          hints: [
            "return sends a result back out of the function — it's different from print(), don't mix them up.",
            'You can store the returned value in a variable, or put the call directly inside print().',
            'def square(number):\n    return number * number\n\nprint(square(4)) — prints 16.',
          ],
        ),
      ],
    ),

    // ISLAND 8: Strings
    LearningIsland(
      id: 'island_strings',
      title: 'Strings Island',
      subtitle: 'Work with text',
      description: 'String methods: uppercase, lowercase, and more.',
      emoji: '🏝️',
      color: const Color(0xFF06B6D4),
      gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
      order: 8,
      nodes: const [
        LearningNode(
          id: 'n_str_1',
          title: 'upper() and lower()',
          description: 'Converting to upper/lower case.',
          tutorial:
              '# text.upper() makes every letter uppercase.\n# text.lower() makes every letter lowercase.\n\nname = "Python"\nprint(name.upper())\nprint(name.lower())',
          starterCode:
              'word = "Hello"\nprint(word.upper())\nprint(word.lower())',
          solution:
              'word = "Hello"\nprint(word.upper())\nprint(word.lower())',
          expectedOutput: 'HELLO\nhello',
          points: 160,
          emoji: '🔤',
          order: 1,
          hints: [
            'text.upper() converts every letter to uppercase.',
            "text.lower() converts every letter to lowercase — it doesn't change the original variable, it returns a new result.",
            'Write print(word.upper()) and print(word.lower()).',
          ],
        ),
        LearningNode(
          id: 'n_str_2',
          title: 'len() on Strings',
          description: 'Find the length of a string.',
          tutorial:
              '# len(text) returns the number of characters.\n\nname = "Python"\nprint(len(name))',
          starterCode: 'sentence = "Hello World"\nprint(len(sentence))',
          solution: 'sentence = "Hello World"\nprint(len(sentence))',
          expectedOutput: '11',
          points: 150,
          emoji: '📐',
          order: 2,
          hints: [
            'len() works on strings the same way it works on lists.',
            'len(text) returns the number of characters, including spaces.',
            'print(len(sentence)) — "Hello World" has 11 characters.',
          ],
        ),
        LearningNode(
          id: 'n_str_3',
          title: 'Replacing with replace()',
          description: 'Replace part of a string.',
          tutorial:
              '# text.replace(old, new) replaces the first argument with the second.\n\nsentence = "I love Java"\nnew_sentence = sentence.replace("Java", "Python")\nprint(new_sentence)',
          starterCode:
              'text = "The dog runs"\nnew_text = text.replace("dog", "cat")\nprint(new_text)',
          solution:
              'text = "The dog runs"\nnew_text = text.replace("dog", "cat")\nprint(new_text)',
          expectedOutput: 'The cat runs',
          points: 170,
          emoji: '🔄',
          order: 3,
          hints: [
            'text.replace(old, new) replaces the old piece of text with the new one.',
            'replace() does NOT change the original string — it returns a NEW string, which you need to store in a variable.',
            'new_text = text.replace("dog", "cat")\nprint(new_text)',
          ],
        ),
      ],
    ),

    // ISLAND 9: Dictionaries
    LearningIsland(
      id: 'island_dicts',
      title: 'Dictionaries Island',
      subtitle: 'Key-value pairs',
      description: 'Dictionaries: access each value with a key.',
      emoji: '🏝️',
      color: const Color(0xFF6366F1),
      gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      order: 9,
      nodes: const [
        LearningNode(
          id: 'n_dict_1',
          title: 'Defining a Dictionary',
          description: 'Create a dictionary with curly braces.',
          tutorial:
              '# dict = {"key": value, ...}\n# Access a value using its key.\n\nperson = {"name": "Alex", "age": 25}\nprint(person["name"])\nprint(person["age"])',
          starterCode:
              'car = {"brand": "BMW", "year": 2020}\nprint(car["brand"])\nprint(car["year"])',
          solution:
              'car = {"brand": "BMW", "year": 2020}\nprint(car["brand"])\nprint(car["year"])',
          expectedOutput: 'BMW\n2020',
          points: 180,
          emoji: '📖',
          order: 1,
          hints: [
            'A dictionary is created with curly braces {} and "key": value pairs.',
            'You access a value using square brackets and its key: dict["key"]',
            'Print car["brand"] and car["year"] on separate lines.',
          ],
        ),
        LearningNode(
          id: 'n_dict_2',
          title: 'Adding to a Dictionary',
          description: 'Add a new key-value pair.',
          tutorial:
              '# dict["new_key"] = value\n\nperson = {"name": "Alex"}\nperson["city"] = "London"\nprint(person)',
          starterCode:
              'product = {"name": "Phone"}\nproduct["price"] = 5000\nprint(product)',
          solution:
              'product = {"name": "Phone"}\nproduct["price"] = 5000\nprint(product)',
          expectedOutput: "{'name': 'Phone', 'price': 5000}",
          points: 190,
          emoji: '➕',
          order: 2,
          hints: [
            "Assigning to a key that doesn't exist yet ADDS a new key-value pair to the dictionary.",
            'Write dict["new_key"] = value — there\'s no such thing as dict.append().',
            'After product["price"] = 5000, print(product) to see the updated dictionary.',
          ],
        ),
      ],
    ),

    // ISLAND 10: Files
    LearningIsland(
      id: 'island_files',
      title: 'Files Island',
      subtitle: 'Make data permanent',
      description:
          'File reading/writing: save data to disk, then load it back.',
      emoji: '🏝️',
      color: const Color(0xFF14B8A6),
      gradient: const [Color(0xFF14B8A6), Color(0xFF06B6D4)],
      order: 10,
      nodes: const [
        LearningNode(
          id: 'n_file_1',
          title: 'Writing to a File',
          description: 'Write to a file using open() and write().',
          tutorial:
              '# open(file, mode) opens the file.\n# "w" = write, "r" = read, "a" = append.\n# write() writes a string.\n\nfile = open("my_notes.txt", "w")\nfile.write("My first note!")\nfile.close()\nprint("Written")',
          starterCode:
              'f = open("test.txt", "w")\nf.write("Hello Python!")\nf.close()\nprint("File written")',
          solution:
              'f = open("test.txt", "w")\nf.write("Hello Python!")\nf.close()\nprint("File written")',
          expectedOutput: 'File written',
          points: 200,
          emoji: '💾',
          order: 1,
          hints: [
            'open(filename, "w") opens the file in WRITE mode (creates it if missing, overwrites if it exists).',
            "file.write(text) writes the content, and don't forget file.close() at the end.",
            'f = open("test.txt", "w")\nf.write("Hello Python!")\nf.close()',
          ],
        ),
        LearningNode(
          id: 'n_file_2',
          title: 'Reading from a File',
          description: 'Read file contents using read().',
          tutorial:
              '# open(file, "r") opens it in read mode.\n# read() returns the whole content as a string.\n\nfile = open("my_notes.txt", "r")\ncontent = file.read()\nfile.close()\nprint(content)',
          starterCode:
              'f = open("test.txt", "w")\nf.write("Line 1\\nLine 2")\nf.close()\n\nf = open("test.txt", "r")\ncontent = f.read()\nf.close()\nprint(content)',
          solution:
              'f = open("test.txt", "w")\nf.write("Line 1\\nLine 2")\nf.close()\n\nf = open("test.txt", "r")\ncontent = f.read()\nf.close()\nprint(content)',
          expectedOutput: 'Line 1\nLine 2',
          points: 220,
          emoji: '📂',
          order: 2,
          hints: [
            'open(filename, "r") opens the file in READ mode.',
            'file.read() returns the ENTIRE file content as one single string.',
            'content = file.read()\nprint(content) — this brings the text you wrote back to the screen.',
          ],
        ),
      ],
    ),

    // ISLAND 11: Algorithms (advanced)
    LearningIsland(
      id: 'island_algorithms',
      title: 'Algorithms Island',
      subtitle: 'Solve real problems with loops',
      description:
          'Find the maximum, calculate an average, count matches — all without relying on built-in shortcuts. This is where real algorithmic thinking begins.',
      emoji: '🧠',
      color: const Color(0xFF3B82F6),
      gradient: const [Color(0xFF3B82F6), Color(0xFF1E40AF)],
      order: 11,
      nodes: const [
        LearningNode(
          id: 'n_algo_1',
          title: 'Find the Maximum',
          description: 'Find the biggest item in a list without using max().',
          tutorial:
              "# Without a max() function, finding the biggest value works like this: treat the first item as 'the biggest so far', then walk the list and update it whenever you find something bigger.\n\nnumbers = [3, 8, 1, 6]\nbiggest = numbers[0]\nfor n in numbers:\n    if n > biggest:\n        biggest = n\nprint(biggest)",
          starterCode:
              'numbers = [4, 9, 2, 7, 5]\nbiggest = numbers[0]\nfor n in numbers:\n    if n > biggest:\n        biggest = n\nprint(biggest)',
          solution:
              'numbers = [4, 9, 2, 7, 5]\nbiggest = numbers[0]\nfor n in numbers:\n    if n > biggest:\n        biggest = n\nprint(biggest)',
          expectedOutput: '9',
          points: 230,
          emoji: '🔍',
          order: 1,
          hints: [
            "There's no built-in max() here — you have to write the logic yourself to FIND the largest value.",
            "Treat the first item as 'the biggest so far', then update it whenever you find something bigger while looping.",
            'biggest = numbers[0]\nfor n in numbers:\n    if n > biggest:\n        biggest = n',
          ],
        ),
        LearningNode(
          id: 'n_algo_2',
          title: 'Sum and Average',
          description: 'Calculate the total and the average of a list.',
          tutorial:
              '# To find a total, start a counter variable at zero and add each item to it as you loop. The average is the total divided by the number of items.\n\nscores = [70, 80, 90]\ntotal = 0\nfor s in scores:\n    total = total + s\naverage = total / len(scores)\nprint(total)\nprint(average)',
          starterCode:
              'scores = [80, 90, 70, 100]\ntotal = 0\nfor s in scores:\n    total = total + s\naverage = total / len(scores)\nprint(total)\nprint(average)',
          solution:
              'scores = [80, 90, 70, 100]\ntotal = 0\nfor s in scores:\n    total = total + s\naverage = total / len(scores)\nprint(total)\nprint(average)',
          expectedOutput: '340\n85.0',
          points: 240,
          emoji: '📊',
          order: 2,
          hints: [
            'To find a total, start a variable at zero and add each item to it inside the loop: total = total + item',
            'The average is the total divided by how many items there are — use len() to get the count.',
            'Accumulate with total = total + s inside the loop, then compute average = total / len(scores).',
          ],
        ),
        LearningNode(
          id: 'n_algo_3',
          title: 'Count Matches',
          description: 'Count how many times a value appears in a list.',
          tutorial:
              '# Start a counter variable at zero, walk the list, and increase the counter every time an item equals the value you\'re looking for.\n\nletters = ["a", "b", "a", "c"]\ncount = 0\nfor l in letters:\n    if l == "a":\n        count = count + 1\nprint(count)',
          starterCode:
              'words = ["cat", "dog", "cats", "bird", "cat"]\ncount = 0\nfor w in words:\n    if w == "cat":\n        count = count + 1\nprint(count)',
          solution:
              'words = ["cat", "dog", "cats", "bird", "cat"]\ncount = 0\nfor w in words:\n    if w == "cat":\n        count = count + 1\nprint(count)',
          expectedOutput: '2',
          points: 250,
          emoji: '🔢',
          order: 3,
          hints: [
            'Start a counter at zero, and increase it every time you find the value you\'re looking for.',
            'Use == to compare: if item == "target":',
            'Put count = count + 1 INSIDE the if block, indented.',
          ],
        ),
      ],
    ),

    // ISLAND 12: Mini Projects (advanced)
    LearningIsland(
      id: 'island_projects',
      title: 'Mini Projects Island',
      subtitle: 'Put it all together',
      description:
          'Combine functions, lists, and dictionaries into small, realistic programs.',
      emoji: '🏆',
      color: const Color(0xFFF43F5E),
      gradient: const [Color(0xFFF43F5E), Color(0xFFBE123C)],
      order: 12,
      nodes: const [
        LearningNode(
          id: 'n_proj_1',
          title: 'Grade Calculator',
          description: 'Write a function that turns a score into a letter grade.',
          tutorial:
              '# A function can chain if/elif/else and return something different from each branch.\n\ndef grade(score):\n    if score >= 90:\n        return "A"\n    elif score >= 70:\n        return "B"\n    else:\n        return "F"\n\nprint(grade(95))',
          starterCode:
              'def grade(score):\n    if score >= 90:\n        return "A"\n    elif score >= 70:\n        return "B"\n    else:\n        return "F"\n\nprint(grade(95))\nprint(grade(75))\nprint(grade(40))',
          solution:
              'def grade(score):\n    if score >= 90:\n        return "A"\n    elif score >= 70:\n        return "B"\n    else:\n        return "F"\n\nprint(grade(95))\nprint(grade(75))\nprint(grade(40))',
          expectedOutput: 'A\nB\nF',
          points: 260,
          emoji: '🎓',
          order: 1,
          hints: [
            'Inside a function you can chain if/elif/else, returning something different from each branch.',
            'Call the function three times with three different scores, and print each result separately.',
            'if score >= 90: return "A" ... elif score >= 70: return "B" ... else: return "F"',
          ],
        ),
        LearningNode(
          id: 'n_proj_2',
          title: 'Parallel List Report',
          description: 'Walk through two lists at once, using an index.',
          tutorial:
              '# If two lists are in the same order (like names and scores), you can access both at once using the same index via range().\n\nnames = ["Alex", "Jamie"]\nscores = [70, 95]\nfor i in range(2):\n    print(f"{names[i]}: {scores[i]}")',
          starterCode:
              'names = ["Alex", "Jamie", "Sam"]\nscores = [85, 92, 78]\nfor i in range(3):\n    print(f"{names[i]}: {scores[i]}")',
          solution:
              'names = ["Alex", "Jamie", "Sam"]\nscores = [85, 92, 78]\nfor i in range(3):\n    print(f"{names[i]}: {scores[i]}")',
          expectedOutput: 'Alex: 85\nJamie: 92\nSam: 78',
          points: 270,
          emoji: '📋',
          order: 2,
          hints: [
            'If two lists are in the same order, you can access both with the same index (i): names[i] and scores[i]',
            'for i in range(3): counts from 0 to 2, matching how many items are in the lists.',
            'for i in range(3):\n    print(f"{names[i]}: {scores[i]}")',
          ],
        ),
        LearningNode(
          id: 'n_proj_3',
          title: 'Score Tracker',
          description:
              'Use a function and a dictionary together to update a scoreboard.',
          tutorial:
              '# You can write a function\'s return value straight back into a dictionary.\n\ndef add_points(current, points):\n    return current + points\n\ntable = {"Alex": 0}\ntable["Alex"] = add_points(table["Alex"], 10)\nprint(table["Alex"])',
          starterCode:
              'def add_points(current, points):\n    return current + points\n\nscoreboard = {"Alex": 0, "Jamie": 0}\nscoreboard["Alex"] = add_points(scoreboard["Alex"], 10)\nscoreboard["Alex"] = add_points(scoreboard["Alex"], 5)\nscoreboard["Jamie"] = add_points(scoreboard["Jamie"], 8)\nprint(scoreboard["Alex"])\nprint(scoreboard["Jamie"])',
          solution:
              'def add_points(current, points):\n    return current + points\n\nscoreboard = {"Alex": 0, "Jamie": 0}\nscoreboard["Alex"] = add_points(scoreboard["Alex"], 10)\nscoreboard["Alex"] = add_points(scoreboard["Alex"], 5)\nscoreboard["Jamie"] = add_points(scoreboard["Jamie"], 8)\nprint(scoreboard["Alex"])\nprint(scoreboard["Jamie"])',
          expectedOutput: '15\n8',
          points: 280,
          emoji: '🏅',
          order: 3,
          hints: [
            'You can write a function\'s return value straight back into a dictionary key: table["Alex"] = function(...)',
            'Read the current value, pass it to the function, and assign the result back to the same key: table["Alex"] = add_points(table["Alex"], 10)',
            'def add_points(current, points):\n    return current + points — then call this while updating the dictionary.',
          ],
        ),
      ],
    ),
  ];
}
