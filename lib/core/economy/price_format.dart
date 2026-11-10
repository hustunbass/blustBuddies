/// Short coin amounts for tight places: 1000 -> `1K`, 2500 -> `2.5K`,
/// 10000 -> `10K`; below 1000 the plain number.
String coinShort(int n) {
  if (n < 1000) return '$n';
  if (n % 1000 == 0) return '${n ~/ 1000}K';
  return '${(n / 1000).toStringAsFixed(1)}K';
}
