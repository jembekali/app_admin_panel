import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Habaye ikibazo mu gukurura amakuru'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nta makuru y\'abakoresha araboneka'));
        }

        final users = snapshot.data!.docs;
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Abakoresha Bashasha mu Misi 7 Iheruka', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue == 0 ? 5 : (maxValue * 1.5),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String weekDay = DateFormat.EEEE('fr_FR').format(sortedDays[group.x.toInt()]);
                          return BarTooltipItem(
                            '$weekDay\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            children: <TextSpan>[
                              TextSpan(
                                text: (rod.toY.toInt()).toString(),
                                style: const TextStyle(color: Colors.yellow, fontSize: 14, fontWeight: FontWeight.w500),
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
                            final day = sortedDays[value.toInt()];
                            return SideTitleWidget(axisSide: meta.axisSide, space: 4.0, child: Text(DateFormat.E('fr_FR').format(day)));
                          },
                          reservedSize: 32,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, 
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                             if (value % 1 == 0) {
                               return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                             }
                             return const Text('');
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
                        barRods: [BarChartRodData(toY: count.toDouble(), color: Colors.indigo, width: 22, borderRadius: BorderRadius.circular(4))],
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