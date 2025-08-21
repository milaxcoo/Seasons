import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/core/theme.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';

class ResultsScreen extends StatelessWidget {
  final model.VotingEvent event;
  const ResultsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Provide a scoped BLoC instance for this screen.
    return BlocProvider(
      create: (context) => VotingBloc(
        votingRepository: RepositoryProvider.of<VotingRepository>(context),
      )..add(FetchResults(eventId: event.id)),
      child: _ResultsView(event: event),
    );
  }
}

class _ResultsView extends StatelessWidget {
  final model.VotingEvent event;
  const _ResultsView({required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${event.title} - Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: BlocBuilder<VotingBloc, VotingState>(
          builder: (context, state) {
            if (state is VotingLoadInProgress) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is VotingResultsLoadSuccess) {
              return _HorizontalBarChart(results: state.results);
            }
            if (state is VotingFailure) {
              return Center(child: Text('Error loading results: ${state.error}'));
            }
            return const Center(child: Text('Loading results...'));
          },
        ),
      ),
    );
  }
}

// A dedicated widget for rendering the bar chart.
class _HorizontalBarChart extends StatelessWidget {
  final List<VoteResult> results;
  const _HorizontalBarChart({required this.results});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100, // Assuming percentages, so max is 100.
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${results[groupIndex].nomineeName}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '${rod.toY.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                final text = results[value.toInt()].nomineeName;
                return SideTitleWidget(
                  meta: meta,
                  space: 8.0,
                  child: Text(text, style: const TextStyle(fontSize: 12)),
                );
              },
              reservedSize: 120,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 20 == 0) {
                  return Text('${value.toInt()}%');
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: results.asMap().entries.map((entry) {
          int index = entry.key;
          VoteResult result = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: result.votePercentage,
                color: AppTheme.primaryColor,
                width: 22,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        gridData: const FlGridData(show: false),
      ),
      swapAnimationDuration: const Duration(milliseconds: 800),
      swapAnimationCurve: Curves.easeInOut,
    );
  }
}
