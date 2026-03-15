// lib/models/tds_reading.dart
class TdsReading {
  final DateTime timestamp;
  final double   tdsPpm;
  final double   ecMScm;

  const TdsReading({
    required this.timestamp,
    required this.tdsPpm,
    required this.ecMScm,
  });

  factory TdsReading.fromJson(Map<String, dynamic> json) => TdsReading(
        timestamp: DateTime.now(),
        tdsPpm:    (json['tds_ppm'] as num).toDouble(),
        ecMScm:    (json['ec_mScm'] as num).toDouble(),
      );

  String toCsvRow() =>
      '${timestamp.toIso8601String()},${tdsPpm.toStringAsFixed(1)},${ecMScm.toStringAsFixed(3)}';

  static const csvHeader = 'timestamp,tds_ppm,ec_mScm';
}