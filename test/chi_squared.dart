import 'dart:io';

import 'package:csv/csv.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class ChiSquared {

}

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

// Map from degrees of freedom to PValues to critical values
final IMap<int, Map<PValue, double>> chi2Crit = _buildChi2Crit();

IMap<int, Map<PValue, double>> _buildChi2Crit() {
  final input = File("test/test_data/chi-squared-critical.csv");
  Csv codec = Csv(fieldDelimiter: "\t");
  List<List<dynamic>> table = codec.decode(input.readAsStringSync());
  for (List<dynamic> line in table) {
    print(line);
  }
  return
}