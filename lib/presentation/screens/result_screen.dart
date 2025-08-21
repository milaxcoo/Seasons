import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../data/repositories/mock_voting_repository.dart';

class ResultsScreen extends StatefulWidget {
  final VotingEvent event;
  const ResultsScreen({super.key, required this.event});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<VoteResult> _results =;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    final results = await MockVotingRepository().getResultsForEvent(widget.event.id);
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event.title} - Results'),
      ),
      body: _isLoading
         ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: BarChart(
                BarChartData(
                  // Set rotation for horizontal chart
                  rotationQuarterTurns: 1,
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100, // Percentage based
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)}%',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          // Rotate the labels to be readable
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8.0,
                            child: Transform.rotate(
                              angle: -3.14 / 2,
                              child: Text(
                                _results[value.toInt()].nomineeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                        reservedSize: 120,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                           if (value % 20!= 0) return const SizedBox.shrink();
                           return Transform.rotate(
                               angle: -3.14 / 2,
                               child: Text('${value.toInt()}%')
                           );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _results.asMap().entries.map((entry) {
                    int index = entry.key;
                    VoteResult result = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods:,
                    );
                  }).toList(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: Colors.grey,
                      strokeWidth: 0.5,
                    ),
                  ),
                ),
                swapAnimationDuration: const Duration(milliseconds: 750),
                swapAnimationCurve: Curves.easeInOut,
              ),
            ),
    );
  }
}