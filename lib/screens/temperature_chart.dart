import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/format.dart';

class TemperatureChart extends StatelessWidget {
  const TemperatureChart({super.key, required this.days});

  final List<DayForecast> days;

  @override
  Widget build(BuildContext context) {
    final maxSpots = <FlSpot>[];
    final minSpots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      if (d.max != null) maxSpots.add(FlSpot(i.toDouble(), d.max!));
      if (d.min != null) minSpots.add(FlSpot(i.toDouble(), d.min!));
    }
    final all = [...maxSpots, ...minSpots].map((s) => s.y).toList();
    if (all.isEmpty) return const SizedBox.shrink();

    final lo = all.reduce(math.min) - 2;
    final hi = all.reduce(math.max) + 2;
    final labels = days.map((d) => shortDateFmt.format(d.date)).toList();
    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));
    const axisStyle = TextStyle(fontSize: 11);

    LineChartBarData line(List<FlSpot> spots, Color color) => LineChartBarData(
          spots: spots,
          color: color,
          barWidth: 3,
          isCurved: false,
          dotData: const FlDotData(show: true),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Temperaturas (°C)',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const Row(
              children: [
                _Legend(color: Colors.deepOrange, label: 'Máxima'),
                SizedBox(width: 16),
                _Legend(color: Colors.blue, label: 'Mínima'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: math.max(days.length - 1, 1).toDouble(),
                  minY: lo,
                  maxY: hi,
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: hidden,
                    rightTitles: hidden,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, meta) =>
                            Text('${v.round()}°', style: axisStyle),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (v != i.toDouble() || i < 0 || i >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(labels[i], style: axisStyle),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map((s) => LineTooltipItem(
                                '${labels[s.x.toInt()]}\n${s.y.round()}°C',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    if (maxSpots.isNotEmpty) line(maxSpots, Colors.deepOrange),
                    if (minSpots.isNotEmpty) line(minSpots, Colors.blue),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
