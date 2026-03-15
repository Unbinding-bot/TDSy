// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_settings.dart';
import '../theme/app_themes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    final s  = ctx.watch<AppSettings>();
    final cs = Theme.of(ctx).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [

          // ════ Appearance ══════════════════════════════════════════════════
          _SectionHeader('Appearance'),

          // Dark mode
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Display mode'),
            subtitle: Text(_themeModeLabel(s.themeMode)),
            onTap: () => _pickThemeMode(ctx, s),
          ),

          // Colour theme
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Colour theme',
                    style: Theme.of(ctx)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppThemeChoice.values
                      .map((c) => _ThemeChip(
                            choice: c,
                            selected: s.themeChoice == c,
                            onTap: () => s.setThemeChoice(c),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // ════ Connection ══════════════════════════════════════════════════
          _SectionHeader('Connection'),

          ListTile(
            leading: const Icon(Icons.wifi_outlined),
            title: const Text('ESP32 IP address'),
            subtitle: Text(s.esp32Ip),
            onTap: () => _editText(
              ctx,
              title: 'ESP32 IP address',
              initial: s.esp32Ip,
              hint: '192.168.4.1',
              onSave: s.setEsp32Ip,
            ),
          ),

          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Poll interval'),
            subtitle: Text('${s.pollIntervalS} seconds'),
            onTap: () => _pickPollInterval(ctx, s),
          ),

          const Divider(height: 24),

          // ════ Data storage ════════════════════════════════════════════════
          _SectionHeader('Data storage'),

          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('CSV save location'),
            subtitle: Text(
              s.savePath.isEmpty ? 'App documents folder (default)' : s.savePath,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _pickFolder(ctx, s),
            trailing: s.savePath.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Reset to default',
                    icon: const Icon(Icons.clear),
                    onPressed: () => s.setSavePath(''),
                  ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _themeModeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => 'Follow system',
        ThemeMode.light  => 'Light',
        ThemeMode.dark   => 'Dark',
      };

  Future<void> _pickThemeMode(BuildContext ctx, AppSettings s) async {
    final choice = await showModalBottomSheet<ThemeMode>(
      context: ctx,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values
              .map((m) => ListTile(
                    title: Text(_themeModeLabel(m)),
                    leading: Icon(switch (m) {
                      ThemeMode.system => Icons.brightness_auto,
                      ThemeMode.light  => Icons.light_mode_outlined,
                      ThemeMode.dark   => Icons.dark_mode_outlined,
                    }),
                    selected: s.themeMode == m,
                    onTap: () => Navigator.pop(c, m),
                  ))
              .toList(),
        ),
      ),
    );
    if (choice != null) s.setThemeMode(choice);
  }

  Future<void> _pickPollInterval(BuildContext ctx, AppSettings s) async {
    final options = [1, 2, 3, 5, 10, 30];
    final choice = await showModalBottomSheet<int>(
      context: ctx,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((v) => ListTile(
                    title: Text('$v second${v == 1 ? "" : "s"}'),
                    selected: s.pollIntervalS == v,
                    onTap: () => Navigator.pop(c, v),
                  ))
              .toList(),
        ),
      ),
    );
    if (choice != null) s.setPollInterval(choice);
  }

  Future<void> _pickFolder(BuildContext ctx, AppSettings s) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose CSV save folder',
    );
    if (result != null) s.setSavePath(result);
  }

  Future<void> _editText(
    BuildContext ctx, {
    required String title,
    required String initial,
    required String hint,
    required Future<void> Function(String) onSave,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final saved = await showDialog<String>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved != null && saved.isNotEmpty) await onSave(saved);
  }
}

// ── Section header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(title,
            style: Theme.of(ctx)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(ctx).colorScheme.primary)),
      );
}

// ── Theme colour chip ──────────────────────────────────────────────────────
class _ThemeChip extends StatelessWidget {
  final AppThemeChoice choice;
  final bool           selected;
  final VoidCallback   onTap;
  const _ThemeChip(
      {required this.choice, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? choice.seed.withValues(alpha: 0.15)
              : Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? choice.seed : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                  color: choice.seed, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(choice.label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected
                        ? choice.seed
                        : Theme.of(ctx).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}