import "package:better_random/better_random.dart";
import "package:checks/checks.dart";
import "package:parameterized_test/parameterized_test.dart";
import "package:sized_ints/sized_ints.dart";
import "package:test/test.dart";

import "chi_squared.dart";

void main() {
  group("BetterRandom Dart API", () {
    BetterRandom br = BetterRandom.usingClock();
    test("nextBool should produce roughly equal numbers of true and false", () {
      int trues = 0;
      int falses = 0;
      for (int i = 0; i < 20000; i++) {
        if (br.nextBool()) {
          trues++;
        } else {
          falses++;
        }
      }
      check(trues)
        ..isGreaterThan(9654)
        ..isLessThan(10346);
      check(falses)
        ..isGreaterThan(9654)
        ..isLessThan(10346);
    });

    test("nextDouble should produce roughly uniformly distributed values", () {
      List<int> count = List.filled(10, 0);
      for (int i = 0; i < 1000; i++) {
        double r = br.nextDouble();
        count[(r * 10) ~/ 1] += 1;
      }
      for (int i = 0; i < 10; i++) {
        check(count[i])
          ..isGreaterThan(50)
          ..isLessThan(150);
      }
    });

    test("nextInt errors when appropriate", () {
      check(() => br.nextInt(0))
          .throws<ArgumentError>()
          .has((e) => e.message, "message")
          .equals("Dart's nextInt only supports max in the range [1, 1<<32]");

      check(() => br.nextInt((1 << 32) + 1))
          .throws<ArgumentError>()
          .has((e) => e.message, "message")
          .equals("Dart's nextInt only supports max in the range [1, 1<<32]");
    });

    test("nextInt can grab lots of correct values", () {
      int zeroes = 0;
      int ones = 0;
      for (int i = 0; i < 20000; i++) {
        int r = br.nextInt(2);
        check(r)
          ..isGreaterOrEqual(0)
          ..isLessOrEqual(1);
        if (r == 0) {
          zeroes++;
        } else {
          ones++;
        }
      }
      check(zeroes)
        ..isGreaterThan(9654)
        ..isLessThan(10346);
      check(ones)
        ..isGreaterThan(9654)
        ..isLessThan(10346);
    });

    group("test nextInt(max) with various ranges", () {
      final int runs = 10000;
      final int divisions = 10;

      parameterizedTest("test nextInt(max) with various maxes",
        [
          1000,
          1_000_000,
          100_000_000,
          1 << 32,
        ],
        (int max) {
          List<int> countsByDecile = List.filled(divisions, 0);
          for (int i = 0; i < runs; i++) {
            int r = br.nextInt(max);
            countsByDecile[r ~/ (max ~/ 10)]++;
          }
          check(lessThanP010Uniform(countsByDecile)).isTrue();
        },
      );
    });
  });
}


