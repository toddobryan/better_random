import 'dart:io';

import 'package:better_random/src/mersenne_twisters.dart';
import 'package:sized_ints/sized_ints.dart';
import 'package:test/test.dart';
import 'package:checks/checks.dart';

void main() {
  // Checks that this implementation matches the output of the C implementation
  // linked in the mersenne_twisters.dart file

  test("1000 outputs of Mersenne32 with seed of 1", () {
    MersenneTwister32 twister32 = MersenneTwister32(1);
    File checkFile = File("test/test_data/twister32-1000.txt");
    List<Uint32> values = checkFile
        .readAsLinesSync()
        .where((s) => !s.startsWith("#"))
        .map((s) => Uint32.fromInt(int.parse(s)))
        .toList();
    assert(values.length == 1000);
    for (int i = 0; i < 1000; i++) {
      check(twister32.randUint32()).equals(values[i]);
    }
  });

  test("1000 outputs of Mersenne64 with seed of 32", () {
    MersenneTwister64 twister32 = MersenneTwister64(37);
    File checkFile = File("test/test_data/twister64-1000.txt");
    List<Uint64> values = checkFile
        .readAsLinesSync()
        .where((s) => !s.startsWith("#"))
        .map((s) => Uint64.parse(s))
        .toList();
    assert(values.length == 1000);
    for (int i = 0; i < 1000; i++) {
      check(twister32.nextUint64()).equals(values[i]);
    }
  });

}
