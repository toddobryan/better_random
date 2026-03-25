import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:sized_ints/sized_ints.dart';

/// A 64-bit cache. A call to nextBits(n) grabs n bits from the left side of
/// the cache, right-aligning them in the output. The left-most bits of the
/// cache are zeroed out. If more bits are requested than are available, the
/// function nextUint64 is called to refresh the cache.
class BitCache {
  Uint64 _cache;
  int _bitsLeftInCache;
  final Uint64 Function() nextUint64;

  BitCache._(this._cache, this._bitsLeftInCache, this.nextUint64);

  factory BitCache(Uint64 Function() nextUint64) =>
      BitCache._(Uint64.zero, 0, nextUint64);

  factory BitCache.withPresets(Uint64 cache, int bitsLeft, Object next) {
    Uint64 Function() nextFun = switch (next) {
      Uint64 _ => () => next,
      Uint64 Function() _ => next,
      _ => throw ArgumentError("provide Uint64 or Uint64 Function() as next")
    };
    return BitCache._(cache, bitsLeft, nextFun);
  }

  Uint64 get cache => _cache;
  int get bitsLeftInCache => _bitsLeftInCache;

  IList<Uint64> nextBits(int n) {
    if (n <= bitsLeftInCache) {
      return IList([getCacheBits(n)]);
    } else if (n <= 64) {
      int numLeftBits = bitsLeftInCache;
      Uint64 leftBits = getCacheBits(bitsLeftInCache);
      // reset cache
      _cache = nextUint64();
      _bitsLeftInCache = 64;
      int numRightBits = n - numLeftBits;
      Uint64 rightBits = getCacheBits(numRightBits);
      Uint64 result = (leftBits << numRightBits) | rightBits;
      return IList([result]);
    } else {
      // the first value will have the "leftover" bits, all others will have 64
      int numBitsInFirst = _numBitsInFirstElement(n);
      List<Uint64> result = List.generate(_uint64sForNumBits(n), (i) {
        if (i == 0) {
          return nextBits(numBitsInFirst)[0];
        } else {
          return nextBits(64)[0];
        }
      });
      return IList(result);
    }
  }

  static int _uint64sForNumBits(int numBits) {
    return (numBits ~/ 64) + (numBits % 64 == 0 ? 0 : 1);
  }

  static int _numBitsInFirstElement(int numBitsTotal) {
    int remainder = numBitsTotal % 64;
    return remainder == 0 ? 64 : remainder;
  }

  // grabs the bits from bitsLeftInCache - 1 down to (and including) lsb
  // bits are numbered 63 to 0 from msb to lsb
  Uint64 getCacheBits(int numBits) {
    assert(bitsLeftInCache >= numBits);
    int msb = bitsLeftInCache - 1;
    int lsb = (msb - numBits) + 1;
    Uint64 maskOnes = (Uint64.one << numBits) - Uint64.one;
    Uint64 mask = maskOnes << lsb;
    Uint64 bits = (cache & mask) >>> lsb;
    // fix cache info
    _bitsLeftInCache -= numBits;
    _cache = cache & ~mask;
    return bits;
  }

  /// Returns the next bit in this BitCache
  int nextBit() {
    if (bitsLeftInCache == 0) {
      _cache = nextUint64();
      _bitsLeftInCache = 64;
    }
    Uint64 valueOfLeftmostBitLeft = Uint64.one << (bitsLeftInCache - 1);
    int bit = ((cache & valueOfLeftmostBitLeft) >>> (bitsLeftInCache - 1))
        .toSafeInt();
    _bitsLeftInCache--;
    return bit;
  }
}

