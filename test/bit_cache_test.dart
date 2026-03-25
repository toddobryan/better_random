import 'package:better_random/src/bit_cache.dart';
import 'package:checks/checks.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:parameterized_test/parameterized_test.dart';
import 'package:sized_ints/sized_ints.dart';
import 'package:test/test.dart';

void main() {
  Uint64 as = Uint64.parse("0xAAAA_AAAA_AAAA_AAAA");

  group("getCacheBits", () {
    Uint64 desc = Uint64.parse("0xFEDC_BA98_7654_3210");
    BitCache bc = BitCache.withPresets(desc, 64, desc);
    parameterizedTest(
      "parameterizedGetCacheBits",
      [
        [1, Uint64.one, 63, Uint64.parse("0x7EDC_BA98_7654_3210")],
        [2, Uint64.fromInt(3), 61, Uint64.parse("0x1EDC_BA98_7654_3210")],
        [5, Uint64.fromInt(0x1E), 56, Uint64.parse("0xDC_BA98_7654_3210")],
        [9, Uint64.fromInt(0x1_B9), 47, Uint64.parse("0x3A98_7654_3210")],
        [15, Uint64.fromInt(0x3A98), 32, Uint64.fromInt(0x7654_3210)],
        [31, Uint64.fromInt(0x3B2A_1908), 1, Uint64.zero],
      ],
          (int numBits, Uint64 result, int bitsLeft, Uint64 newCache) {
        check(bc.getCacheBits(numBits)).equals(result);
        check(bc.bitsLeftInCache).equals(bitsLeft);
        check(bc.cache).equals(newCache);
      },
      customDescriptionBuilder: (group, index, values) =>
      "$index: (numBits: ${values[0]}, result: ${values[1]}, bitsLeft: ${values[2]}, newCache: ${values[3]})",
    );
    test("ask for too many bits throws AssertionError", () {
      check(() => bc.getCacheBits(2)).throws<AssertionError>();
      check(bc.bitsLeftInCache).equals(1);
      check(bc.cache).equals(Uint64.zero);
    });
  });

  parameterizedTest("nextBits and check cache and bitsLeft",
    [
      [0xF, 4, 1, 1, 7, null],
      [0xF, 4, 2, 3, 3, null],
      [0xF, 4, 3, 7, 1, null],
      [0xF, 4, 4, 0xF, 0, null],
      [0xF, 4, 5, 0x1F, "0x7FFF_FFFF_FFFF_FFFF", Uint64.max],
      ["0xFABC_0123_89D4_5679", 64, 32, 0xFABC_0123, 0x89D4_5679, null],
      ["0xFABC_0123_89D4_5679", 64, 64, "0xFABC_0123_89D4_5679", 0, null],
      ["0xFABC_0123_89D4_5679", 64, 33, "0x1_F578_0247", "0x9D4_5679", null],
      [Uint64.max, 64, 128, [Uint64.max, as], 0, as],
      [Uint64.max, 64, 69, [0x1F, "0xFFFF_FFFF_FFFF_FFF5"], "0x02AA_AAAA_AAAA_AAAA", as],
      [as >>> 1, 64, 65, [0, "0xAAAA_AAAA_AAAA_AAAB"], "0x2AAA_AAAA_AAAA_AAAA", as],
    ],
    (Object cacheVal, int bitsLeft, int numBits, Object expected, Object expectedCache, Object? nextUint64) {
      BitCache bc = BitCache.withPresets(
          makeUint64(cacheVal), bitsLeft, nextUint64 ?? Uint64.zero);
      check(bc.nextBits(numBits)).equals(toUint64IList(expected));
      check(bc.cache).equals(makeUint64(expectedCache));
      check(bc.bitsLeftInCache).equals((bitsLeft - numBits) % 64);
    },
  );

  group("nextBits", () {
    Uint64 desc = Uint64.parse("0xFEDC_BA98_7654_3210");
    BitCache bc = BitCache.withPresets(desc, 64, desc);

    parameterizedTest(
      "parameterizedNextBits",
      [
        [1, Uint64.one],
        [2, Uint64.fromInt(3)],
        [5, Uint64.fromInt(0x1E)],
        [9, Uint64.fromInt(0x1_B9)],
        [15, Uint64.fromInt(0x3A98)],
        [31, Uint64.fromInt(0x3B2A_1908)],
        // spans boundary with next cache
        [8, Uint64.fromInt(0x7F)],
      ],
      (int numBits, Uint64 result) {
        check(bc.nextBits(numBits)).equals(IList([result]));
      },
      customDescriptionBuilder: (group, index, values) =>
          "$index: (numBits: ${values.first}, result: ${values[1]}",
    );
  });
}

Uint64 makeUint64(Object value) => switch (value) {
  Uint64 _ => value,
  String _ => Uint64.parse(value),
  int _ => Uint64.fromInt(value),
  _ => throw ArgumentError("makeUint64 takes String or int, given $value"),
};

IList<Uint64> toUint64IList(Object value) => switch (value) {
  List<Object> _ => IList(value.map(makeUint64)),
  IList<Uint64> _ => value,
  Uint64 _ => IList([value]),
  _ => IList([makeUint64(value)]),
};