// lib/models/app_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';

class AppSettings extends ChangeNotifier {
  // ── Defaults ─────────────────────────────────────────────────────────────
  ThemeMode        _themeMode      = ThemeMode.system;
  AppThemeChoice   _themeChoice    = AppThemeChoice.systemBlue;
  String           _savePath       = '';   // empty = app Documents folder
  int              _pollIntervalS  = 3;    // seconds between ESP32 polls
  String           _esp32Ip        = '192.168.4.1';

  // ── Getters ───────────────────────────────────────────────────────────────
  ThemeMode        get themeMode      => _themeMode;
  AppThemeChoice   get themeChoice    => _themeChoice;
  String           get savePath       => _savePath;
  int              get pollIntervalS  => _pollIntervalS;
  String           get esp32Ip        => _esp32Ip;

  // ── Load from SharedPreferences ──────────────────────────────────────────
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _themeMode     = ThemeMode.values[p.getInt('themeMode')     ?? 0];
    _themeChoice   = AppThemeChoice.values[p.getInt('themeChoice') ?? 0];
    _savePath      = p.getString('savePath')      ?? '';
    _pollIntervalS = p.getInt('pollIntervalS')    ?? 3;
    _esp32Ip       = p.getString('esp32Ip')       ?? '192.168.4.1';
    notifyListeners();
  }

  // ── Setters (each persists immediately) ──────────────────────────────────
  Future<void> setThemeMode(ThemeMode v) async {
    _themeMode = v;
    final p = await SharedPreferences.getInstance();
    await p.setInt('themeMode', v.index);
    notifyListeners();
  }

  Future<void> setThemeChoice(AppThemeChoice v) async {
    _themeChoice = v;
    final p = await SharedPreferences.getInstance();
    await p.setInt('themeChoice', v.index);
    notifyListeners();
  }

  Future<void> setSavePath(String v) async {
    _savePath = v;
    final p = await SharedPreferences.getInstance();
    await p.setString('savePath', v);
    notifyListeners();
  }

  Future<void> setPollInterval(int v) async {
    _pollIntervalS = v;
    final p = await SharedPreferences.getInstance();
    await p.setInt('pollIntervalS', v);
    notifyListeners();
  }

  Future<void> setEsp32Ip(String v) async {
    _esp32Ip = v;
    final p = await SharedPreferences.getInstance();
    await p.setString('esp32Ip', v);
    notifyListeners();
  }
}