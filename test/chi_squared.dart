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

final IMap<int, Map<PValue, double>> chi2Crit = _buildChi2Crit();

IMap<int, Map<PValue, double>> _buildChi2Crit() {

}