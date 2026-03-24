import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:sized_ints/sized_ints.dart';

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

  /// Returns the next bit in this BitCache
  int nextBit() {
    if (bitsLeftInCache == 0) {
      _cache = nextUint64();
      _bitsLeftInCache = 64;
    }
    Uint64 valueOfLeftmostBitLeft = Uint64.one << (bitsLeftInCache - 1);
    int bit = ((cache & valueOfLeftmostBitLeft) >>> (bitsLeftInCache - 1))
        .toSafeInt();
    _cache = _cache >>> 1;
    _bitsLeftInCache--;
    return bit;
  }

  IList<Uint64> nextBits(int n) {
    if (n <= bitsLeftInCache) {
      return IList([getCacheBits(n)]);
    } else {
      return const IList.empty();
    }
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

  /*
  /// Returns the next n bits in this BitCache as a list of
  /// Uint64s, with the bits starting at the n % 64th bit in element 0
  /// and each subsequent element having all 64 bits full.
  List<Uint64> nextBits(int n) {
    List<Uint64> res = List.generate(_uint64sForNumBits(n), (i) {
      if (i == 0) {
        return _getNBits(_numBitsInFirstElement(n));
      } else {
        return _getNBits(64);
      }
    });
    return res;
  }

  static int _uint64sForNumBits(int numBits) {
    return (numBits ~/ 64) + (numBits % 64 == 0 ? 0 : 1);
  }

  /// Returns the next n bits in this BitCache as the lower n bits
  /// of a Uint64. Requires n <= 64
  Uint64 _getNBits(int n) {
    assert(n <= 64, "Can only grab up to 64 bits");
    Uint64 result;
    if (n <= bitsLeftInCache) {
      result = cache >>> (bitsLeftInCache - n);
      cache = cache._zeroOutLeftNBits(n);
      bitsLeftInCache -= n;
    } else {
      int numOfOrigBits = bitsLeftInCache;
      Uint64 origBits = cache;
      int numOfNextBits = n - numOfOrigBits;
      cache = nextUint64();
      bitsLeftInCache = 64;
      Uint64 nextBits = _getNBits(numOfNextBits);
      result = (origBits << numOfNextBits) | nextBits;
    }
    return result;
  }

  int _numBitsInFirstElement(int numBitsTotal) {
    int remainder = numBitsTotal % 64;
    return remainder == 0 ? 64 : remainder;
  }*/
}

extension ZeroOut on Uint64 {
  Uint64 _zeroOutLeftNBits(int n) => this & (Uint64.max << n);
}
