import 'package:better_random/src/bit_cache.dart';
import 'package:checks/checks.dart';
import 'package:sized_ints/sized_ints.dart';
import 'package:test/test.dart';

void main() {
  print(6341068275337658367.toRadixString(16));

  Uint64 as = Uint64.parse("0xAAAA_AAAA_AAAA_AAAA");

  BitCache makeBitCache(Uint64 cache, int bitsLeft, Uint64 randInt) {
    BitCache bc = BitCache(() => randInt);
    bc.cache = cache;
    bc.bitsLeftInCache = bitsLeft;
    return bc;
  }

  void checkGetNBits(
    Uint64 cache,
    int bitsLeft,
    int n,
    Uint64 expected,
    Uint64 expectedLeftInCache, {
    Uint64? nextUint64,
  }) {
    BitCache bc = makeBitCache(cache, bitsLeft, nextUint64 ?? Uint64.zero);
    List<Uint64> nb = bc.nextBits(n);
    print(nb);
    check(nb[0]).equals(expected);
    check(bc.cache).equals(expectedLeftInCache);
    check(bc.bitsLeftInCache).equals((bitsLeft - n) % 64);
  }

  test("getNBits", () {
    checkGetNBits(Uint64.fromInt(0xF), 4, 1, Uint64.one, Uint64.fromInt(7));
    checkGetNBits(
      Uint64.fromInt(0xF),
      4,
      2,
      Uint64.fromInt(3),
      Uint64.fromInt(3),
    );
    checkGetNBits(Uint64.fromInt(0xF), 4, 3, Uint64.fromInt(7), Uint64.one);
    checkGetNBits(Uint64.fromInt(0xF), 4, 4, Uint64.fromInt(0xF), Uint64.zero);
    checkGetNBits(
      Uint64.fromInt(0xF),
      4,
      5,
      Uint64.fromInt(31),
      Uint64.max >>> 1,
      nextUint64: Uint64.max,
    );
  });

  test("getLotsOfBits", () {
    checkGetNBits(
      Uint64.parse("0xFABC_0123_89D4_5679"),
      64,
      32,
      Uint64.fromInt(0xFABC_0123),
      Uint64.fromInt(0x89D4_5679),
    );
    checkGetNBits(
      Uint64.parse("0xFABC_0123_89D4_5679"),
      64,
      64,
      Uint64.parse("0xFABC_0123_89D4_5679"),
      Uint64.zero,
    );
    checkGetNBits(
      Uint64.parse("0xFABC_0123_89D4_5679"),
      64,
      33,
      Uint64.parse("0x1_89D4_5679"),
      Uint64.fromInt(0x7D5E_0091),
    );
  });

  test("getMoreThan64Bits", () {
    BitCache bc = makeBitCache(Uint64.max, 64, as);
    check(bc.nextBits(128)).containsEqualInOrder([Uint64.max, as]);
    check(bc.cache).equals(Uint64.zero);
    check(bc.bitsLeftInCache).equals(0);

    BitCache bc2 = makeBitCache(Uint64.max, 64, as);
    check(bc2.nextBits(69)).containsEqualInOrder([Uint64.fromInt(0x1F), Uint64.parse("0x57FF_FFFF_FFFF_FFFF")]);
    check(bc2.cache).equals(Uint64.parse("0x0555_5555_5555_5555"));
    check(bc2.bitsLeftInCache).equals(59);
  });

  test("bits across the 64 bit barrier", () {
    BitCache bc = makeBitCache(as >>> 1, 64, as);
    List<Uint64> nb = bc.nextBits(65);
    check(nb).containsEqualInOrder([Uint64.one, Uint64.parse("0xD555_5555_5555_5555")]);
  });
}
