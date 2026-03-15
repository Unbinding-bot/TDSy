// lib/providers/tds_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tds_reading.dart';
import '../models/app_settings.dart';
import '../services/esp32_service.dart';
import '../services/csv_service.dart';

enum ConnectionState { disconnected, connecting, connected, error }

class TdsProvider extends ChangeNotifier {
  final AppSettings settings;

  TdsProvider(this.settings);

  // ── State ─────────────────────────────────────────────────────────────────
  ConnectionState connectionState = ConnectionState.disconnected;
  TdsReading?     latest;
  final List<TdsReading> history  = [];  // newest first, capped at 500
  static const int _historyMax    = 500;

  String   _csvPath     = '';
  String   get csvPath  => _csvPath;
  bool     _isPolling   = false;
  Timer?   _pollTimer;
  String   _errorMsg    = '';
  String   get errorMsg => _errorMsg;

  // ── Start/stop polling ────────────────────────────────────────────────────
  Future<void> startPolling() async {
    if (_isPolling) return;
    _isPolling = true;
    connectionState = ConnectionState.connecting;
    notifyListeners();

    // Create a fresh CSV file for this session
    _csvPath = await CsvService.resolveFilePath(settings.savePath);

    _pollTimer = Timer.periodic(
      Duration(seconds: settings.pollIntervalS),
      (_) => _poll(),
    );
    await _poll(); // immediate first fetch
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
    connectionState = ConnectionState.disconnected;
    notifyListeners();
  }

  bool get isPolling => _isPolling;

  // ── Single poll ───────────────────────────────────────────────────────────
  Future<void> _poll() async {
    final svc = Esp32Service(settings.esp32Ip);
    final reading = await svc.fetchLatest();
    if (reading == null) {
      connectionState = ConnectionState.error;
      _errorMsg = 'Cannot reach ${settings.esp32Ip}';
      notifyListeners();
      return;
    }

    connectionState = ConnectionState.connected;
    _errorMsg = '';
    latest = reading;

    // Add to history
    history.insert(0, reading);
    if (history.length > _historyMax) history.removeLast();

    // Append to CSV (single row per poll)
    await CsvService.append(_csvPath, [reading]);

    notifyListeners();
  }

  // ── Download ESP32's own buffer and merge ────────────────────────────────
  Future<int> downloadEsp32History() async {
    final svc      = Esp32Service(settings.esp32Ip);
    final incoming = await svc.fetchHistory();
    if (incoming.isEmpty) return 0;

    await CsvService.append(_csvPath.isNotEmpty
        ? _csvPath
        : await CsvService.resolveFilePath(settings.savePath), incoming);

    // Merge, deduplicate roughly by prepending (ESP history already newest-first)
    history.insertAll(0, incoming);
    if (history.length > _historyMax) history.removeRange(_historyMax, history.length);
    notifyListeners();
    return incoming.length;
  }

  // ── Share CSV ─────────────────────────────────────────────────────────────
  Future<void> shareCsv() async {
    if (_csvPath.isEmpty) return;
    await CsvService.share(_csvPath);
  }

  // ── Clear ─────────────────────────────────────────────────────────────────
  void clearLocalHistory() {
    history.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}