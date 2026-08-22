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
        ),
      ],
    ),
  ];
}
