import 'dart:typed_data';

import 'package:sized_ints/sized_ints.dart';

import 'bit_cache.dart';
import 'mersenne_twisters.dart';

class BetterRandomState {
  final int seed;
  final MersenneTwister64State twister;
  final BitCache bitCache;

  BetterRandomState(this.seed, this.twister, this.bitCache);
}

class BetterRandom {
  int seed;
  MersenneTwister64 _twister;
  BitCache _bitCache;

  static final int _bitsInInt64 = 64;

  static final Uint64 _lower32Mask = Uint64.fromInt(0xFFFF_FFFF);
  static final Int64 _maxInt32PlusOne = Int64.parse("0x8000_0000");

  BetterRandom._(this.seed, this._twister, this._bitCache);

  factory BetterRandom(int seed) {
    MersenneTwister64 mt = MersenneTwister64(seed);
    BitCache bitCache = BitCache(mt.nextUint64);
    return BetterRandom._(seed, mt, bitCache);
  }

  BetterRandomState get state =>
      BetterRandomState(seed, _twister.state, _bitCache);

  void setState(BetterRandomState state) {
    seed = state.seed;
    _twister = MersenneTwister64.fromState(state.twister);
    _bitCache = state.bitCache;
  }

  factory BetterRandom.usingClock() =>
      BetterRandom(DateTime.now().microsecondsSinceEpoch % 0x8000_0000);

  /* Compatibility functions for dart:math's Random */
  bool nextBool() => _bitCache.nextBits(1)[0] == Uint64.zero;

  // returns a random double in the range [0.0, 1.0)
  double nextDouble() {
    return _bitCache.nextBits(53)[0].toDouble() / 9007199254740992.0;
  }

  int nextInt(int max) {
    if (max < 1 || max > (1 << 32)) {
      throw ArgumentError(
        "Dart's nextInt only supports max in the range [1, 1<<32]",
      );
    }
    return nextNonNegIntBelow(max);
  }

  /* Methods based on java.util.Random */

  int _next(int bits) {
    if (bits < 1 || bits > 32) {
      throw ArgumentError("bits must be in range [1, 32]");
    }
    return _bitCache.nextBits(bits)[0].toSafeInt();
  }

  /// returns a random int on the interval [0, 255]
  int nextByte() => _bitCache.nextBits(8)[0].toSafeInt();

  Uint8List nextBytes(int n) =>
      Uint8List.fromList(List<int>.generate(n, (i) => nextByte()));

  /// returns a uniformly distributed int in the range that this environment
  /// supports [-2^63, 2^63-1] for native, and [-2^53, 2^53-1] for web
  int nextSignedInt() => _nextSafeInt();

  int nextNonNegIntBelow(int? upperExc) => nextIntInBounds(0, upperExc);

  /// Returns an int that is safe for the current platform uniformly
  /// distributed in the range [lowerInc, upperExclusive). Use
  /// null to include the max int value.
  int nextIntInBounds(int lowerInc, int? upperExc) {
    if (upperExc != null && upperExc <= lowerInc) {
      throw ArgumentError(
        "upper must be greater than lower, "
        "given $lowerInc and $upperExc",
      );
    }
    int r = _nextSafeInt();
    BigInt n = upperExc != null
        ? BigInt.from(upperExc) - BigInt.from(lowerInc)
        : BigInt.from(EnvForSafeInt.current.maxInteger) -
              BigInt.from(lowerInc);
    BigInt m = n - BigInt.one;
    if (n & m == BigInt.zero) {
      r = (BigInt.from(r) & m + BigInt.from(lowerInc)).toSafeInt();
    } else if (n < BigInt.from(EnvForSafeInt.current.maxInteger)) {
      int mm = m.toSafeInt();
      int nn = n.toSafeInt();
      int u = r >>> 1;
      r = u % nn;
      while (u + mm - r < 0) {
        u = _nextSafeInt() >>> 1;
        r = u % nn;
      }
      r += lowerInc;
    } else {
      while (r < lowerInc || (upperExc != null && r >= upperExc)) {
        r = _nextSafeInt();
      }
    }
    return r;
  }
  
  int _nextSafeInt() {
    Uint64 bits = _bitCache.nextBits(EnvForSafeInt.current.maxBitLength)[0];
    print(bits);
    int safeInt = Int64(bits.bitList.uints).toSafeInt();
    print(safeInt.hex);
    return safeInt;
  }
}
