import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

enum PValue {
  p995,
  p990,
  p975,
  p950,
  p900,
  p100,
  p050,
  p025,
  p010,
  p005,
}

bool lessThanP010Uniform(List<int> counts) {
  double chi2 = _chi2Uniform(counts);
  return chi2 < chi2Crit[counts.length - 1]![PValue.p010]!;
}

// Finds the chi^2 value, assuming each slot is equally likely
// (a uniform distribution)
double _chi2Uniform(List<int> counts) {
  int sum = counts.reduce((acc, elt) => acc + elt);
  double expected = sum / counts.length;
  double chi2 = (counts.map((c) => pow(c - expected, 2))
      .reduce((acc, elt) => acc + elt) / expected);
  return chi2;
}

// Map from degrees of freedom to PValues to critical values
final IMap<int, IMap<PValue, double>> chi2Crit = _buildChi2Crit();

IMap<int, IMap<PValue, double>> _buildChi2Crit() {
  final input = File("test/test_data/chi-squared-critical.csv");
  Csv codec = Csv(fieldDelimiter: "\t");
  List<List<dynamic>> table = codec.decode(input.readAsStringSync());
  Map<int, IMap<PValue, double>> builder = {};
  for (List<dynamic> row in table.sublist(1)) {
    Map<PValue, double> critVals = {};
    for (int i = 1; i < row.length; i++) {
      critVals[PValue.values[i - 1]] = double.parse(row[i] as String);
    }
    builder[int.parse(row[0] as String)] = IMap(critVals);
  }
  return IMap(builder);
}