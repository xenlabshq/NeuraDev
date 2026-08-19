import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/learning/data/python_simulator.dart';

void main() {
  late PythonSimulator sim;

  setUp(() => sim = PythonSimulator());

  group('PythonSimulator print & variables', () {
    test('print with string literal', () {
      final result = sim.run('print("merhaba")');
      expect(result.success, isTrue);
      expect(result.output, ['merhaba']);
    });

    test('assignment then print', () {
      final result = sim.run('x = 5\nprint(x)');
      expect(result.output, ['5']);
    });

    test('arithmetic: addition, subtraction, multiplication, division', () {
      final result = sim.run('''
a = 10
b = 3
print(a + b)
print(a - b)
print(a * b)
print(a / b)
''');
      expect(result.output, ['13', '7', '30', '3.3333333333333335']);
    });

    test('string concatenation', () {
      final result = sim.run('name = "Ada"\nprint("Merhaba " + name)');
      expect(result.output, ['Merhaba Ada']);
    });

    test('f-string interpolation', () {
      final result = sim.run('x = 3\nprint(f"deger: {x}")');
      expect(result.output, ['deger: 3']);
    });
  });

  group('PythonSimulator comparison & control flow', () {
    test('comparison operators', () {
      final result = sim.run('''
print(3 < 5)
print(3 > 5)
print(3 == 3)
print(3 != 4)
''');
      expect(result.output, ['True', 'False', 'True', 'True']);
    });

    test('if / else picks correct branch', () {
      final result = sim.run('''
x = 10
if x > 5:
    print("buyuk")
else:
    print("kucuk")
''');
      expect(result.output, ['buyuk']);
    });

    test('if / elif / else chain', () {
      final result = sim.run('''
x = 5
if x > 10:
    print("A")
elif x > 3:
    print("B")
else:
    print("C")
''');
      expect(result.output, ['B']);
    });

    test('for i in range(N) loop', () {
      final result = sim.run('''
for i in range(3):
    print(i)
''');
      expect(result.output, ['0', '1', '2']);
    });

    test('for x in list loop', () {
      final result = sim.run('''
for x in [1, 2, 3]:
    print(x)
''');
      expect(result.output, ['1', '2', '3']);
    });

    test('while loop with counter', () {
      final result = sim.run('''
i = 0
while i < 3:
    print(i)
    i = i + 1
''');
      expect(result.output, ['0', '1', '2']);
    });
  });

  group('PythonSimulator lists & builtins', () {
    test('len() on list and string', () {
      final result = sim.run('''
print(len([1, 2, 3]))
print(len("abcd"))
''');
      expect(result.output, ['3', '4']);
    });

    test('empty list literal', () {
      final result = sim.run('items = []\nprint(len(items))');
      expect(result.output, ['0']);
    });
  });

  group('PythonSimulator errors', () {
    test('division by zero produces ZeroDivisionError', () {
      final result = sim.run('x = 1 / 0');
      expect(result.success, isFalse);
      expect(result.errors.first, contains('ZeroDivisionError'));
    });

    test('unrecognized statement produces NameError', () {
      final result = sim.run('bilinmeyen_ifade_@@@');
      expect(result.success, isFalse);
      expect(result.errors.first, contains('NameError'));
    });

    test('infinite while loop is stopped by the iteration guard', () {
      final result = sim.run('''
i = 0
while i < 1000000:
    i = i - 1
''');
      expect(result.success, isFalse);
      expect(result.errors.first, contains('RuntimeError'));
    });

    test('generates a hint when there is an error', () {
      final result = sim.run('x = 1 / 0');
      expect(result.hint, isNotNull);
    });
  });

  group('PythonSimulator state isolation', () {
    test('run() clears state from the previous run', () {
      sim.run('x = 1\nprint(x)');
      final second = sim.run('print("temiz")');
      expect(second.output, ['temiz']);
    });
  });

  group('PythonSimulator execution steps (canlı değişken izleyici)', () {
    test('records one step per assignment with a variable snapshot', () {
      final result = sim.run('x = 1\ny = 2');
      expect(result.steps.length, 2);
      expect(result.steps[0].line, 1);
      expect(result.steps[0].variables, {'x': 1});
      expect(result.steps[1].line, 2);
      expect(result.steps[1].variables, {'x': 1, 'y': 2});
    });

    test('a print step carries its printed output', () {
      final result = sim.run('x = 5\nprint(x)');
      expect(result.steps[1].printedOutput, '5');
    });

    test('earlier steps keep their own snapshot after later reassignment', () {
      final result = sim.run('x = 1\nx = 2\nx = 3');
      expect(result.steps[0].variables, {'x': 1});
      expect(result.steps[1].variables, {'x': 2});
      expect(result.steps[2].variables, {'x': 3});
    });

    test('a for loop records one step per body-line per iteration', () {
      final result = sim.run('for i in range(3):\n    x = i');
      // 3 iterasyon × 1 satır (x = i) = 3 adım.
      expect(result.steps.length, 3);
      expect(result.steps.map((s) => s.variables['x']), [0, 1, 2]);
    });

    test('steps are capped so a long loop cannot grow unbounded', () {
      final result = sim.run('for i in range(1000):\n    x = i');
      expect(result.steps.length, lessThanOrEqualTo(300));
    });

    test('a failed line is not recorded as a step', () {
      final result = sim.run('x = 1\nbilinmeyen_ifade_@@@');
      expect(result.steps.length, 1);
      expect(result.steps.single.variables, {'x': 1});
    });
  });
}
