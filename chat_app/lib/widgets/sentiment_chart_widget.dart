import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Self-contained chart widget for displaying conversation sentiment analysis.
///
/// Renders a line chart showing sentiment scores over messages, with
/// mood and trend indicators.
class SentimentChartWidget extends StatelessWidget {
  final String jsonData;

  const SentimentChartWidget({super.key, required this.jsonData});

  /// Tries to extract sentiment chart JSON from a message string.
  /// Returns null if no chart data is found.
  static String? extractChartData(String message) {
    // Look for the __SENTIMENT_CHART__ marker in tool results or agent response
    try {
      // Pattern 1: JSON key-value with escaped string value
      final markerRegex = RegExp(
        r'"__SENTIMENT_CHART__"\s*:\s*"((?:[^"\\]|\\.)*)"',
      );
      final match = markerRegex.firstMatch(message);
      if (match != null) {
        final escaped = match.group(1)!;
        final unescaped = escaped
            .replaceAll(r'\"', '"')
            .replaceAll(r'\\', r'\');
        // Validate it's parseable JSON
        json.decode(unescaped);
        return unescaped;
      }

      // Pattern 2: JSON key-value with object value (not string-escaped)
      final objectRegex = RegExp(
        r'"__SENTIMENT_CHART__"\s*:\s*(\{[^}]*"data_points"[^}]*\[.*?\]\s*\})',
        dotAll: true,
      );
      final objMatch = objectRegex.firstMatch(message);
      if (objMatch != null) {
        final candidate = objMatch.group(1)!;
        json.decode(candidate);
        return candidate;
      }
    } catch (_) {
      // Fall through to return null
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Map<String, dynamic> data;
    try {
      data = json.decode(jsonData) as Map<String, dynamic>;
    } catch (_) {
      return const SizedBox.shrink();
    }

    final contactName = data['contact_name'] as String? ?? 'Contact';
    final overallMood = data['overall_mood'] as String? ?? 'neutral';
    final score = (data['score'] as num?)?.toDouble() ?? 0.0;
    final trend = data['trend'] as String? ?? 'stable';
    final dataPoints = data['data_points'] as List<dynamic>? ?? [];

    if (dataPoints.isEmpty) return const SizedBox.shrink();

    // Build spots for the line chart
    final spots = <FlSpot>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i] as Map<String, dynamic>;
      final s = (point['score'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), s));
    }

    // Mood emoji
    final moodEmoji = switch (overallMood) {
      'positive' => '\u{1F60A}',
      'negative' => '\u{1F614}',
      'mixed' => '\u{1F914}',
      _ => '\u{1F610}',
    };

    // Trend arrow
    final trendArrow = switch (trend) {
      'improving' => '\u{2197}\u{FE0F}',
      'declining' => '\u{2198}\u{FE0F}',
      _ => '\u{27A1}\u{FE0F}',
    };

    // Chart colors
    final lineColor = score > 0.2
        ? Colors.green
        : score < -0.2
            ? Colors.red
            : Colors.grey;

    final gradientColors = [
      lineColor.withOpacity(0.8),
      lineColor.withOpacity(0.3),
    ];

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(
                '$moodEmoji Mood with $contactName',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Text(
                '$trendArrow ${trend[0].toUpperCase()}${trend.substring(1)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            'Score: ${score.toStringAsFixed(2)} ($overallMood)',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          // Chart
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: -1.0,
                maxY: 1.0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 0.5,
                      getTitlesWidget: (value, meta) {
                        String text;
                        if (value == 1.0) {
                          text = '+1';
                        } else if (value == 0.0) {
                          text = '0';
                        } else if (value == -1.0) {
                          text = '-1';
                        } else {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          text,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: lineColor,
                          strokeWidth: 1.5,
                          strokeColor: isDark ? Colors.black : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: gradientColors,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final label = idx < dataPoints.length
                            ? (dataPoints[idx] as Map<String, dynamic>)['label']
                                as String? ?? ''
                            : '';
                        return LineTooltipItem(
                          '$label\n${spot.y.toStringAsFixed(2)}',
                          TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          // Legend
          Text(
            '${dataPoints.length} messages analyzed',
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
