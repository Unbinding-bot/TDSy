// lib/screens/graph_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/tds_provider.dart';
import '../models/tds_reading.dart';

enum _Range { last20, last100, all }

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});
  @override State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  _Range _range = _Range.last100;

  List<TdsReading> _slice(List<TdsReading> history) {
    final reversed = history.reversed.toList(); // oldest first
    return switch (_range) {
      _Range.last20  => reversed.length > 20
          ? reversed.sublist(reversed.length - 20)
          : reversed,
      _Range.last100 => reversed.length > 100
          ? reversed.sublist(reversed.length - 100)
          : reversed,
      _Range.all     => reversed,
    };
  }

  @override
  Widget build(BuildContext ctx) {
    final provider = ctx.watch<TdsProvider>();
    final cs       = Theme.of(ctx).colorScheme;
    final slice    = _slice(provider.history);

    // Stats
    double minTds = double.infinity, maxTds = -double.infinity, sumTds = 0;
    for (final r in slice) {
      if (r.tdsPpm < minTds) minTds = r.tdsPpm;
      if (r.tdsPpm > maxTds) maxTds = r.tdsPpm;
      sumTds += r.tdsPpm;
    }
    final avgTds = slice.isEmpty ? 0.0 : sumTds / slice.length;

    final spots = List.generate(
        slice.length, (i) => FlSpot(i.toDouble(), slice[i].tdsPpm));

    final timeFmt = DateFormat('HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text('TDS Graph'),
        actions: [
          IconButton(
            tooltip: 'Share CSV',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => provider.shareCsv(),
          ),
          IconButton(
            tooltip: 'Clear local history',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              provider.clearLocalHistory();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Range selector ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<_Range>(
              segments: const [
                ButtonSegment(value: _Range.last20,  label: Text('Last 20')),
                ButtonSegment(value: _Range.last100, label: Text('Last 100')),
                ButtonSegment(value: _Range.all,     label: Text('All')),
              ],
              selected: {_range},
              onSelectionChanged: (s) => setState(() => _range = s.first),
            ),
          ),

          const SizedBox(height: 16),

          // ── Stats row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatChip(label: 'Min',  value: '${minTds == double.infinity ? "—" : minTds.toStringAsFixed(0)} ppm', color: cs.primary),
                const SizedBox(width: 8),
                _StatChip(label: 'Avg',  value: '${avgTds.toStringAsFixed(0)} ppm', color: cs.secondary),
                const SizedBox(width: 8),
                _StatChip(label: 'Max',  value: '${maxTds == -double.infinity ? "—" : maxTds.toStringAsFixed(0)} ppm', color: cs.tertiary),
                const Spacer(),
                Text('${slice.length} pts',
                    style: Theme.of(ctx)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Chart ────────────────────────────────────────────────────────
          Expanded(
            child: slice.length < 2
                ? Center(
                    child: Text('Not enough data yet.',
                        style: TextStyle(color: cs.onSurfaceVariant)))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 24, 16),
                    child: LineChart(
                      LineChartData(
                        clipData: FlClipData.all(),
                        minY: (minTds * 0.9).floorToDouble(),
                        maxY: (maxTds * 1.1).ceilToDouble(),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                              strokeWidth: 0.5),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              getTitlesWidget: (v, _) => Text(
                                  '${v.toInt()}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant)),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval:
                                  (slice.length / 4).ceilToDouble(),
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= slice.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                      timeFmt
                                          .format(slice[idx].timestamp),
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: cs.onSurfaceVariant)),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: cs.primary,
                            barWidth: 2,
                            dotData: FlDotData(show: slice.length < 30),
                            belowBarData: BarAreaData(
                              show: true,
                              color: cs.primary.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots
                                .map((s) => LineTooltipItem(
                                      '${s.y.toStringAsFixed(0)} ppm\n${timeFmt.format(slice[s.x.toInt()].timestamp)}',
                                      TextStyle(
                                          color: cs.onPrimaryContainer,
                                          fontSize: 12),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: color)),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}