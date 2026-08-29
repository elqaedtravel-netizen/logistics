import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';

class RevenueLineChart extends StatefulWidget {
  final List<double> weeklyData;
  final List<String> days;

  const RevenueLineChart({
    super.key,
    required this.weeklyData,
    required this.days,
  });

  @override
  State<RevenueLineChart> createState() => _RevenueLineChartState();
}

class _RevenueLineChartState extends State<RevenueLineChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(16, 20, 24, 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5000,
            getDrawingHorizontalLine: (val) => FlLine(
              color: AppColors.border.withOpacity(0.6),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (val, meta) {
                  if (val % 10000 == 0) {
                    return Text(
                      '${(val / 1000).toInt()}k',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (idx, meta) {
                  final int index = idx.toInt();
                  if (index >= 0 && index < widget.days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.days[index],
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (widget.weeklyData.length - 1).toDouble(),
          minY: 0,
          maxY: 45000,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.sidebarBg,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(0)} ج.م',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                widget.weeklyData.length,
                (i) => FlSpot(i.toDouble(), widget.weeklyData[i]),
              ),
              isCurved: true,
              color: AppColors.accent,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: AppColors.accent,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.35),
                    AppColors.accent.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderStatusDonutChart extends StatefulWidget {
  final Map<String, int> statusMap;

  const OrderStatusDonutChart({super.key, required this.statusMap});

  @override
  State<OrderStatusDonutChart> createState() => _OrderStatusDonutChartState();
}

class _OrderStatusDonutChartState extends State<OrderStatusDonutChart> {
  int _touchedSection = -1;

  Color _getColor(String s) {
    switch (s) {
      case 'Pending': return AppColors.statusPending;
      case 'In_Warehouse': return AppColors.statusInWarehouse;
      case 'Dispatched_to_Driver': return AppColors.statusDispatched;
      case 'Delivered': return AppColors.statusDelivered;
      case 'Postponed': return AppColors.statusPostponed;
      case 'Canceled': return AppColors.statusCanceled;
      case 'Returned': return AppColors.statusReturned;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.statusMap.entries.toList();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedSection = -1;
                        return;
                      }
                      _touchedSection = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                startDegreeOffset: -90,
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 45,
                sections: entries.asMap().entries.map((item) {
                  final idx = item.key;
                  final entry = item.value;
                  final isTouched = idx == _touchedSection;
                  final double radius = isTouched ? 48.0 : 40.0;
                  final color = _getColor(entry.key);
                  final pct = total > 0 ? ((entry.value / total) * 100).toStringAsFixed(0) : '0';

                  return PieChartSectionData(
                    color: color,
                    value: entry.value.toDouble(),
                    title: isTouched ? '$pct%' : '',
                    radius: radius,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((e) {
              final color = _getColor(e.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        e.key.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${e.value}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class DriverLeaderboardCard extends StatelessWidget {
  const DriverLeaderboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final topDrivers = [
      {'rank': '🥇', 'name': 'أحمد محمود', 'hub': 'المعادي', 'orders': 148, 'cash': '١١٢,٤٠٠ ج.م', 'rating': 4.9},
      {'rank': '🥈', 'name': 'محمود حسن', 'hub': 'مدينة نصر', 'orders': 132, 'cash': '٩٤,٨٠٠ ج.م', 'rating': 4.8},
      {'rank': '🥉', 'name': 'إبراهيم علي', 'hub': 'التجمع الخامس', 'orders': 119, 'cash': '٨٦,٥٠٠ ج.م', 'rating': 4.8},
      {'rank': '4', 'name': 'كريم سامي', 'hub': 'الدقي والمهندسين', 'orders': 105, 'cash': '٧٨,٢٠٠ ج.م', 'rating': 4.7},
    ];

    return Column(
      children: topDrivers.map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text(d['rank'] as String, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('خط سير: ${d['hub']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${d['orders']} أوردر مسلم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.statusDelivered)),
                  Text(d['cash'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
