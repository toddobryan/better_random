import 'dart:typed_data';

import 'package:sized_ints/sized_ints.dart';

import 'bit_cache.dart';

/*
   Copyright (C) 2004, Makoto Matsumoto and Takuji Nishimura,
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

     1. Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

     2. Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.

     3. The names of its contributors may not be used to endorse or promote
        products derived from this software without specific prior written
        permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

   References:
   T. Nishimura, ``Tables of 64-bit Mersenne Twisters''
     ACM Transactions on Modeling and
     Computer Simulation 10. (2000) 348--357.
   M. Matsumoto and T. Nishimura,
     ``Mersenne Twister: a 623-dimensionally equidistributed
       uniform pseudorandom number generator''
     ACM Transactions on Modeling and
     Computer Simulation 8. (Jan. 1998) 3--30.

   Any feedback is very welcome.
   http://www.math.hiroshima-u.ac.jp/~m-mat/MT/emt.html
   email: m-mat @ math.sci.hiroshima-u.ac.jp (remove spaces)

   Based on the C code found at:
   https://www.math.sci.hiroshima-u.ac.jp/m-mat/MT/VERSIONS/C-LANG/mt19937-64.c
*/

class MersenneTwister64State {
  final int seed;
  final List<Uint64> mt;
  final int mti;

  MersenneTwister64State(this.seed, this.mt, this.mti);
}

class MersenneTwister64 {
  static final int nn = 312;
  static final int mm = 156;
  static final matrixA = Uint64.parse("0xB5026F5AA96619E9");
  static final um = Uint64.parse("0xFFFF_FFFF_8000_0000");
  static final lm = Uint64.parse("0x7FFF_FFFF");
  static final magicConstant = Uint64.parse("0x5851_F42D_4C95_7F2D");


  final int seed;
  final List<Uint64> _mt;
  int _mti = 0;

  MersenneTwister64._(this.seed, this._mt, this._mti);

  factory MersenneTwister64.fromState(MersenneTwister64State state) =>
    MersenneTwister64._(state.seed, state.mt, state.mti);

  factory MersenneTwister64(int seed) {
    List<Uint64> mt = List<Uint64>.filled(nn, Uint64.zero);
    mt[0] = Uint64.fromInt(seed);
    for (int i = 1; i < nn; i++) {
      mt[i] = magicConstant * (mt[i - 1] ^ (mt[i - 1] >> 62)) + Uint64.fromInt(i);
    }
    return MersenneTwister64._(seed, mt, 0);
  }

  MersenneTwister64State get state =>
    MersenneTwister64State(seed, List.from(_mt), _mti);

  static Uint64 temper1 = Uint64.parse("0x5555_5555_5555_5555");
  static Uint64 temper2 = Uint64.parse("0x71D6_7FFF_EDA6_0000");
  static Uint64 temper3 = Uint64.parse("0xFFF7_EEE0_0000_0000");

  Uint64 nextUint64() {
    if (_mti == 0) {
      _generateNewNumbers();
    }

    Uint64 x = _mt[_mti];

    x = x ^ ((x >> 29) & temper1);
    x = x ^ ((x << 17) & temper2);
    x = x ^ ((x << 37) & temper3);
    x = x ^ (x >> 43);

    _mti = (_mti + 1) % nn;

    return x;
  }

  static List<Uint64> mag01 = List.from([Uint64.zero, matrixA]);

  void _generateNewNumbers() {
    Uint64 x;
    for (int i=0; i < nn - mm; i++) {
      x = (_mt[i] & um) | (_mt[i+1] & lm);
      _mt[i] = _mt[i + mm] ^ (x >> 1) ^ mag01[(x & Uint64.one).toSafeInt()];
    }
    for (int i = nn - mm; i < nn - 1; i++) {
      x = (_mt[i] & um) | (_mt[i + 1] & lm);
      _mt[i] = _mt[i + (mm - nn)] ^ (x >> 1) ^ mag01[(x & Uint64.one).toSafeInt()];
    }
    x = (_mt[nn - 1] & um) | (_mt[0] & lm);
    _mt[nn - 1] = _mt[mm - 1] ^ (x>>1) ^ mag01[(x & Uint64.one).toSafeInt()];
  }
}

/*
  Copyright (C) 2001-2009 Makoto Matsumoto and Takuji Nishimura.
  Copyright (C) 2009 Mutsuo Saito
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  Based on C code at
  https://github.com/MersenneTwister-Lab/dcmt/blob/master/lib/mt19937.c
  and the associated header file.
*/
class MersenneTwister32 {
  static final int n = 624;
  static final int m = 397;

  static final Uint32 upperMask = Uint32.fromInt(0x8000_0000);
  static final Uint32 lowerMask = Uint32.fromInt(0x7FFF_FFFF);
  static final Uint32 temperingMaskB = Uint32.fromInt(0x9D2C_5680);
  static final Uint32 temperingMaskC = Uint32.fromInt(0xEFC6_0000);


  static final Uint32 matrixA = Uint32.fromInt(0x9908_b0df);
  static final Uint32 constructorMagicConstant = Uint32.fromInt(0x6c07_8965);

  final int seed;
  int _index = 0;
  final List<Uint32> _mt;

  MersenneTwister32._(this.seed, this._mt);

  factory MersenneTwister32(int seed) {
    List<Uint32> mt = List<Uint32>.filled(n, Uint32.zero);
    mt[0] = Uint32.fromInt(seed);
    for (int i = 1; i < n; i++) {
      mt[i] = constructorMagicConstant * (mt[i - 1] ^ (mt[i - 1] >> 30)) +
          Uint32.fromInt(i);
    }
    return MersenneTwister32._(seed, mt);
  }

  static List<Uint32> mag01 = List.from([Uint32.zero, matrixA]);

  Uint32 randUint32() {
    if (_index == 0) {
      _generateNumbers();
    }

    Uint32 y = _mt[_index];
    y = y ^ (y >> 11);
    y = y ^ ((y << 7) & temperingMaskB);
    y = y ^ ((y << 15) & temperingMaskC);
    y = y ^ (y >> 18);

    _index = (_index + 1) % n;
    return y;
  }

  void _generateNumbers() {
    Uint32 y;
    for (int i = 0; i < n - m; i++) {
      y = (_mt[i] & upperMask) | (_mt[i + 1] & lowerMask);
      _mt[i] = _mt[i + m] ^ (y >> 1) ^ mag01[(y & Uint32.one).toSafeInt()];
    }
    for (int i = n - m; i < n - 1; i++) {
      y = (_mt[i] & upperMask) | (_mt[i + 1] & lowerMask);
      _mt[i] = _mt[i + (m - n)] ^ (y >> 1) ^ mag01[(y & Uint32.one).toSafeInt()];
    }
    y = (_mt[n - 1] & upperMask) | (_mt[0] & lowerMask);
    _mt[n - 1] = _mt[m - 1] ^ (y >> 1) ^ mag01[(y & Uint32.one).toSafeInt()];
  }
}
