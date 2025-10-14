import 'dart:math' as math;
import 'dart:ui'; // Import for ImageFilter
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/widgets/app_background.dart';

class ResultsScreen extends StatelessWidget {
  final model.VotingEvent event;
  // FIXED: Added imagePath to receive the background from HomeScreen
  final String imagePath;

  const ResultsScreen({
    super.key,
    required this.event,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VotingBloc(
        votingRepository: RepositoryProvider.of<VotingRepository>(context),
      )..add(FetchResults(eventId: event.id)),
      child: AppBackground(
        // FIXED: Use the passed imagePath
        imagePath: imagePath,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.2),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                '${event.title} - Результаты',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
            ),
            body: _ResultsView(),
          ),
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: BlocBuilder<VotingBloc, VotingState>(
        builder: (context, state) {
          if (state is VotingLoadInProgress) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (state is VotingResultsLoadSuccess) {
            return _HorizontalBarChart(results: state.results);
          }
          if (state is VotingFailure) {
            return Center(
              child: Text(
                'Ошибка загрузки результатов: ${state.error}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            );
          }
          return const Center(child: Text('Загрузка результатов...', style: TextStyle(color: Colors.white)));
        },
      ),
    );
  }
}

class _HorizontalBarChart extends StatelessWidget {
  final List<VoteResult> results;
  const _HorizontalBarChart({required this.results});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
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
                  child: Transform.rotate(
                    angle: -math.pi / 4,
                    child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)), // Text color to white
                  ),
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
                  return Text('${value.toInt()}%', style: const TextStyle(color: Colors.white70)); // Text color to white
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
                color: Theme.of(context).colorScheme.primary,
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
