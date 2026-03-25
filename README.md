# BetterRandom

An improvement of Dart's math.Random class (at least in my opinion)
that uses a 64-bit Mersenne Twister PRNG to generate random numbers.

It is platform-aware and can return random ints within the platform's
supported range (64-bit for wasm and native, and 53-bit for JS). In
addition to the nextInt(), nextDouble(), and nextBool() methods (which
allows it to be used as a drop-in replacement for math.Random), it also
provides a several methods modeled on Java's java.util.Random class.
