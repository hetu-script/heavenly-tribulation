import "dart:math";

// Box-Muller正态分布算法，根据平均数和方差，得到在一定范围内的随机数
late double _z0, _z1;
bool _generate = true;

double gaussianNoise(double mean, double variance) {
  const double pi2 = 3.14159265358979323846 * 2.0;

  _generate = !_generate;

  if (_generate) {
    return _z1 * variance + mean;
  }

  double u1 = Random().nextDouble();
  double u2 = Random().nextDouble();

  _z0 = sqrt(-2.0 * log(u1)) * cos(pi2 * u2);
  _z1 = sqrt(-2.0 * log(u1)) * sin(pi2 * u2);
  return _z0 * variance + mean;
}

double radiusToSigma(double radius) {
  return radius * 0.57735 + 0.5;
}
