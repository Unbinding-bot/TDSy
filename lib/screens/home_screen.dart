// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tds_reading.dart';
import '../providers/tds_provider.dart';
import 'graph_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-start polling on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TdsProvider>().startPolling();
    });
  }

  // TDS quality label
  ({String label, Color color}) _quality(double tds, BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    if (tds < 50)   return (label: 'Excellent',    color: const Color(0xFF0F6E56));
    if (tds < 150)  return (label: 'Good',         color: const Color(0xFF1D9E75));
    if (tds < 250)  return (label: 'Acceptable',   color: const Color(0xFFBA7517));
    if (tds < 500)  return (label: 'Poor',         color: cs.error);
    return            (label: 'Very Poor',          color: cs.error);
  }

  @override
  Widget build(BuildContext ctx) {
    final provider = ctx.watch<TdsProvider>();
    final latest   = provider.latest;
    final cs       = Theme.of(ctx).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TDS Monitor'),
        actions: [
          // Connection toggle
          IconButton(
            tooltip: provider.isPolling ? 'Disconnect' : 'Connect',
            icon: Icon(provider.isPolling
                ? Icons.wifi
                : Icons.wifi_off),
            color: provider.connectionState == Esp32ConnectionState.connected
                ? const Color(0xFF1D9E75)
                : null,
            onPressed: () => provider.isPolling
                ? provider.stopPolling()
                : provider.startPolling(),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!provider.isPolling) await provider.startPolling();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Status chip ────────────────────────────────────────────────
            _StatusBanner(state: provider.connectionState, error: provider.errorMsg),

            const SizedBox(height: 20),

            // ── Main TDS card ──────────────────────────────────────────────
            Card(
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  children: [
                    Text('Total Dissolved Solids',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            color: cs.onPrimaryContainer)),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        latest != null
                            ? '${latest.tdsPpm.toStringAsFixed(0)} ppm'
                            : '— ppm',
                        key: ValueKey(latest?.tdsPpm.toStringAsFixed(0)),
                        style: Theme.of(ctx).textTheme.displayLarge?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (latest != null) ...[
                      const SizedBox(height: 8),
                      _QualityBadge(
                          quality: _quality(latest.tdsPpm, ctx)),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── EC card ────────────────────────────────────────────────────
            Card(
              child: ListTile(
                leading: Icon(Icons.bolt_outlined, color: cs.primary),
                title: const Text('Electrical Conductivity'),
                trailing: Text(
                  latest != null
                      ? '${latest.ecMScm.toStringAsFixed(2)} mS/cm'
                      : '—',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Mini sparkline ─────────────────────────────────────────────
            if (provider.history.length > 1) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent readings',
                              style: Theme.of(ctx).textTheme.titleSmall),
                          TextButton.icon(
                            onPressed: () => Navigator.push(ctx,
                                MaterialPageRoute(
                                    builder: (_) => const GraphScreen())),
                            icon: const Icon(Icons.open_in_full, size: 16),
                            label: const Text('Full graph'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: _SparkLine(history: provider.history),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Actions row ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () async {
                      final n = await provider.downloadEsp32History();
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('Downloaded $n records from device')));
                      }
                    },
                    child: const Text('Sync device history'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: provider.history.isEmpty
                        ? null
                        : () => provider.shareCsv(),
                    child: const Text('Share CSV'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status banner ──────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final Esp32ConnectionState state;
  final String error;
  const _StatusBanner({required this.state, required this.error});

  @override
  Widget build(BuildContext ctx) {
    final (icon, label, color) = switch (state) {
      Esp32ConnectionState.connected    => (Icons.wifi,       'Connected',   const Color(0xFF0F6E56)),
      Esp32ConnectionState.connecting   => (Icons.wifi_find,  'Connecting…', Colors.orange),
      Esp32ConnectionState.error        => (Icons.wifi_off,   error,         Colors.red),
      Esp32ConnectionState.disconnected => (Icons.wifi_off,   'Disconnected', Colors.grey),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: Theme.of(ctx)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color)),
        ),
      ],
    );
  }
}

// ── Quality badge ──────────────────────────────────────────────────────────
class _QualityBadge extends StatelessWidget {
  final ({String label, Color color}) quality;
  const _QualityBadge({required this.quality});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: quality.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: quality.color.withValues(alpha: 0.4)),
      ),
      child: Text(quality.label,
          style: TextStyle(
              color: quality.color, fontWeight: FontWeight.w500, fontSize: 13)),
    );
  }
}

// ── Sparkline (last 50 points) ─────────────────────────────────────────────
class _SparkLine extends StatelessWidget {
  final List<TdsReading> history;
  const _SparkLine({required this.history});

  @override
  Widget build(BuildContext ctx) {
    final points = history.take(50).toList().reversed.toList();
    final spots = List.generate(points.length,
        (i) => FlSpot(i.toDouble(), points[i].tdsPpm));

    final cs = Theme.of(ctx).colorScheme;
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant.withValues(alpha: 0.3), strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ),
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: cs.primary,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}