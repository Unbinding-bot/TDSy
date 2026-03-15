// lib/services/esp32_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tds_reading.dart';

class Esp32Service {
  final String baseUrl; // e.g. "http://192.168.4.1"

  Esp32Service(String ip) : baseUrl = 'http://$ip';

  /// Fetches the latest single TDS reading.
  /// Returns null on error.
  Future<TdsReading?> fetchLatest() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return TdsReading.fromJson(json);
      }
    } catch (_) {}
    return null;
  }

  /// Downloads the ESP32's in-memory CSV history.
  /// Returns list of readings, newest first.
  Future<List<TdsReading>> fetchHistory() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/history'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];

      final lines = const LineSplitter().convert(res.body);
      final readings = <TdsReading>[];
      for (final line in lines.skip(1)) { // skip header
        final parts = line.split(',');
        if (parts.length < 3) continue;
        final tsMs = int.tryParse(parts[0]) ?? 0;
        final tds  = double.tryParse(parts[1]) ?? 0.0;
        final ec   = double.tryParse(parts[2]) ?? 0.0;
        readings.add(TdsReading(
          timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
          tdsPpm:    tds,
          ecMScm:    ec,
        ));
      }
      return readings;
    } catch (_) {
      return [];
    }
  }

  /// Tells the ESP32 to wipe its buffer.
  Future<bool> clearHistory() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/clear'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}