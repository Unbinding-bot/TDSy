// lib/services/csv_service.dart
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/tds_reading.dart';

class CsvService {
  /// Returns the full path of the current session CSV file.
  /// If [customDir] is provided (from Settings), that directory is used;
  /// otherwise falls back to the app's Documents directory.
  static Future<String> resolveFilePath(String customDir) async {
    final dir = customDir.isNotEmpty
        ? Directory(customDir)
        : await getApplicationDocumentsDirectory();

    if (!await dir.exists()) await dir.create(recursive: true);

    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${dir.path}/tds_$stamp.csv';
  }

  /// Appends a batch of readings to [filePath].
  /// Creates the file (with header) if it does not exist yet.
  static Future<void> append(
      String filePath, List<TdsReading> readings) async {
    final file   = File(filePath);
    final exists = await file.exists();
    final sink   = file.openWrite(mode: FileMode.append);

    if (!exists) sink.writeln(TdsReading.csvHeader);
    for (final r in readings) {
      sink.writeln(r.toCsvRow());
    }
    await sink.flush();
    await sink.close();
  }

  /// Shares the CSV file using the OS share sheet.
  static Future<void> share(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    await Share.shareXFiles([XFile(filePath)], text: 'TDS Monitor data');
  }
}