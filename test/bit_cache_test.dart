import 'package:better_random/src/bit_cache.dart';
import 'package:checks/checks.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:sized_ints/sized_ints.dart';
import 'package:test/test.dart';

void main() {
  print(6341068275337658367.toRadixString(16));

  Uint64 as = Uint64.parse("0xAAAA_AAAA_AAAA_AAAA");

  void checkGetNBits(
    Uint64 cache,
    int bitsLeft,
    int n,
    Uint64 expected,
    Uint64 expectedLeftInCache, {
    Uint64? nextUint64,
  }) {
    BitCache bc = BitCache.withPresets(cache, bitsLeft, nextUint64 ?? Uint64.zero);
    IList<Uint64> nb = bc.nextBits(n);
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
    BitCache bc = BitCache.withPresets(Uint64.max, 64, as);
    check(bc.nextBits(128)).containsEqualInOrder([Uint64.max, as]);
    check(bc.cache).equals(Uint64.zero);
    check(bc.bitsLeftInCache).equals(0);

    BitCache bc2 = BitCache.withPresets(Uint64.max, 64, as);
    check(bc2.nextBits(69)).containsEqualInOrder([Uint64.fromInt(0x1F), Uint64.parse("0x57FF_FFFF_FFFF_FFFF")]);
    check(bc2.cache).equals(Uint64.parse("0x0555_5555_5555_5555"));
    check(bc2.bitsLeftInCache).equals(59);
  });

  test("bits across the 64 bit barrier", () {
    BitCache bc = BitCache.withPresets(as >>> 1, 64, as);
    IList<Uint64> nb = bc.nextBits(65);
    check(nb).containsEqualInOrder([Uint64.one, Uint64.parse("0xD555_5555_5555_5555")]);
  });

  test("getCacheBits", () {
    Uint64 desc = Uint64.parse("0xFEDC_BA98_7654_3210");
    BitCache bc = BitCache.withPresets(desc, 64, desc);

    check(bc.getCacheBits(1)).equals(Uint64.one);
    check(bc.bitsLeftInCache).equals(63);
    check(bc.cache).equals(Uint64.parse("0x7EDC_BA98_7654_3210"));

    check(bc.getCacheBits(2)).equals(Uint64.fromInt(3));
    check(bc.bitsLeftInCache).equals(61);
    check(bc.cache).equals(Uint64.parse("0x1EDC_BA98_7654_3210"));

    check(bc.getCacheBits(5)).equals(Uint64.fromInt(0x1E));
    check(bc.bitsLeftInCache).equals(56);
    check(bc.cache).equals(Uint64.parse("0xDC_BA98_7654_3210"));

    check(bc.getCacheBits(9)).equals(Uint64.fromInt(0x1_B9));
    check(bc.bitsLeftInCache).equals(47);
    check(bc.cache).equals(Uint64.parse("0x3A98_7654_3210"));

    check(bc.getCacheBits(15)).equals(Uint64.fromInt(0x3A98));
    check(bc.bitsLeftInCache).equals(32);
    check(bc.cache).equals(Uint64.fromInt(0x7654_3210));

    check(bc.getCacheBits(31)).equals(Uint64.fromInt(0x3B2A_1908));
    check(bc.bitsLeftInCache).equals(1);
    check(bc.cache).equals(Uint64.zero);

    check(() => bc.getCacheBits(2)).throws<AssertionError>();
    check(bc.bitsLeftInCache).equals(1);
    check(bc.cache).equals(Uint64.zero);
  });

  test("nextBits", () {
    Uint64 desc = Uint64.parse("0xFEDC_BA98_7654_3210");
    BitCache bc = BitCache.withPresets(desc, 64, desc);

    check(bc.nextBits(1)).equals(IList([Uint64.one]));
    check(bc.nextBits(2)).equals(IList([Uint64.fromInt(3)]));
    check(bc.nextBits(5)).equals(IList([Uint64.fromInt(0x1E)]));
    check(bc.nextBits(9)).equals(IList([Uint64.fromInt(0x1_B9)]));
    check(bc.nextBits(15)).equals(IList([Uint64.fromInt(0x3A98)]));
    check(bc.nextBits(31)).equals(IList([Uint64.fromInt(0x3B2A_1908)]));
    check(bc.nextBits(8)).equals(IList([Uint64.fromInt(0x7F)]));
  });
}
