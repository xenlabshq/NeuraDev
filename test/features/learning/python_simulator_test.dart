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

  group('PythonSimulator lists (indeksleme + append)', () {
    test('index read returns the element at that position', () {
      final result = sim.run(
        'meyveler = ["elma", "armut", "muz"]\n'
        'print(meyveler[0])\n'
        'print(meyveler[2])',
      );
      expect(result.output, ['elma', 'muz']);
    });

    test('append mutates the list in place', () {
      final result = sim.run(
        'sayilar = [10, 20]\nsayilar.append(30)\nprint(sayilar)',
      );
      expect(result.output, ['[10, 20, 30]']);
    });

    test('index assignment replaces an element', () {
      final result = sim.run(
        'liste = [1, 2, 3]\nliste[1] = 99\nprint(liste)',
      );
      expect(result.output, ['[1, 99, 3]']);
    });

    test('out-of-bounds index produces IndexError', () {
      final result = sim.run('liste = [1, 2]\nprint(liste[5])');
      expect(result.success, isFalse);
      expect(result.errors.first, contains('IndexError'));
    });
  });

  group('PythonSimulator dicts', () {
    test('literal + key read', () {
      final result = sim.run(
        'araba = {"marka": "BMW", "yil": 2020}\n'
        'print(araba["marka"])\n'
        'print(araba["yil"])',
      );
      expect(result.output, ['BMW', '2020']);
    });

    test('item assignment adds a new key', () {
      final result = sim.run(
        'urun = {"ad": "Telefon"}\nurun["fiyat"] = 5000\nprint(urun)',
      );
      expect(result.output, ["{'ad': 'Telefon', 'fiyat': 5000}"]);
    });

    test('missing key produces KeyError', () {
      final result = sim.run('d = {"a": 1}\nprint(d["b"])');
      expect(result.success, isFalse);
      expect(result.errors.first, contains('KeyError'));
    });
  });

  group('PythonSimulator functions (def/return)', () {
    test('a void function runs its body as a side effect', () {
      final result = sim.run('def selam():\n    print("Selam!")\n\nselam()');
      expect(result.output, ['Selam!']);
    });

    test('a function can be called multiple times with different args', () {
      final result = sim.run(
        'def kare(sayi):\n    print(sayi * sayi)\n\nkare(5)\nkare(7)',
      );
      expect(result.output, ['25', '49']);
    });

    test('return sends a value back to the call site', () {
      final result = sim.run(
        'def kare(sayi):\n    return sayi * sayi\n\n'
        'print(kare(4))\nprint(kare(9))',
      );
      expect(result.output, ['16', '81']);
    });

    test('code after return inside the function does not execute', () {
      final result = sim.run(
        'def f():\n    return 1\n    print("olmamali")\n\nprint(f())',
      );
      expect(result.output, ['1']);
    });
  });

  group('PythonSimulator string methods', () {
    test('upper and lower', () {
      final result = sim.run(
        'kelime = "Merhaba"\nprint(kelime.upper())\nprint(kelime.lower())',
      );
      expect(result.output, ['MERHABA', 'merhaba']);
    });

    test('replace', () {
      final result = sim.run(
        'metin = "Köpek koşuyor"\n'
        'yeni = metin.replace("Köpek", "Kedi")\n'
        'print(yeni)',
      );
      expect(result.output, ['Kedi koşuyor']);
    });
  });

  group('PythonSimulator files (sanal dosya sistemi)', () {
    test('write then read round-trips the exact content', () {
      final result = sim.run(
        'f = open("test.txt", "w")\n'
        'f.write("Satır 1\\nSatır 2")\n'
        'f.close()\n\n'
        'f = open("test.txt", "r")\n'
        'icerik = f.read()\n'
        'f.close()\n'
        'print(icerik)',
      );
      expect(result.output, ['Satır 1\nSatır 2']);
    });

    test('opening in "w" mode truncates prior content', () {
      final result = sim.run(
        'f = open("a.txt", "w")\nf.write("ilk")\nf.close()\n\n'
        'f = open("a.txt", "w")\nf.write("ikinci")\nf.close()\n\n'
        'f = open("a.txt", "r")\nprint(f.read())\nf.close()',
      );
      expect(result.output, ['ikinci']);
    });
  });

  group('PythonSimulator stringify (Python doğru gösterim)', () {
    test('a whole-number float from division keeps its .0', () {
      final result = sim.run('print(81 / 9)');
      expect(result.output, ['9.0']);
    });

    test('a string inside a list is quoted like Python repr', () {
      final result = sim.run('print(["a", "b"])');
      expect(result.output, ["['a', 'b']"]);
    });
  });
}
