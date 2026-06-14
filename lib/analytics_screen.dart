import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. KUBARA ITARIKI Y'IMINSI 7 ISHIZE
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final timestampThreshold = Timestamp.fromDate(sevenDaysAgo);

    return FutureBuilder<QuerySnapshot>(
      // 🔥 OPTIMIZATION: Soma gusa abinjiye mu minsi 7 ishize (Reads nkeya)
      future: FirebaseFirestore.instance
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: timestampThreshold)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Habaye ikibazo mu gukwega amakuru', style: TextStyle(color: Colors.white)));
        }

        final users = snapshot.data?.docs ?? [];
        final now = DateTime.now();
        
        final dailyCounts = <DateTime, int>{};
        for (int i = 0; i < 7; i++) {
          final day = DateTime(now.year, now.month, now.day - i);
          dailyCounts[day] = 0;
        }

        for (var userDoc in users) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (data['createdAt'] != null) {
            final createdAt = (data['createdAt'] as Timestamp).toDate();
            final dayOnly = DateTime(createdAt.year, createdAt.month, createdAt.day);
            if (dailyCounts.containsKey(dayOnly)) {
              dailyCounts[dayOnly] = dailyCounts[dayOnly]! + 1;
            }
          }
        }
        
        final sortedDays = dailyCounts.keys.toList()..sort();
        int maxValue = dailyCounts.values.fold(0, (prev, element) => element > prev ? element : prev);

        return Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Abakoresha Bashasha (Iminsi 7)', 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
              ),
              const SizedBox(height: 10),
              Text(
                'Muri iyindwi hinjiye abantu ${users.length}.',
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue == 0 ? 5 : (maxValue * 1.2),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.indigo,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String weekDay = DateFormat.EEEE().format(sortedDays[group.x.toInt()]);
                          return BarTooltipItem(
                            '$weekDay\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            children: <TextSpan>[
                              TextSpan(
                                text: (rod.toY.toInt()).toString(),
                                style: const TextStyle(color: Colors.amber, fontSize: 16),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= sortedDays.length) return const Text('');
                            final day = sortedDays[value.toInt()];
                            return SideTitleWidget(
                              axisSide: meta.axisSide, 
                              space: 8.0, 
                              child: Text(DateFormat.E().format(day), style: const TextStyle(color: Colors.grey, fontSize: 10))
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, 
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                             return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                          },
                        )
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: sortedDays.asMap().entries.map((entry) {
                      final index = entry.key;
                      final day = entry.value;
                      final count = dailyCounts[day]!;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: count.toDouble(), 
                            color: Colors.amber, 
                            width: 25, 
                            borderRadius: BorderRadius.circular(6),
                            // 🔥 KOSORA HANO: Izina ry'ukuri ni BackgroundBarChartRodData
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true, 
                              toY: maxValue.toDouble() == 0 ? 5 : maxValue.toDouble(), 
                              color: Colors.white.withAlpha(15) // Nashyizemo withAlpha aho gukoresha opacity
                            )
                          )
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}