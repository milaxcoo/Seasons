import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/widgets/app_background.dart';

class ResultsScreen extends StatelessWidget {
  final model.VotingEvent event;
  final String imagePath;

  const ResultsScreen({
    super.key,
    required this.event,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      imagePath: imagePath,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.35),
                  ],
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: _ResultsView(event: event),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  final model.VotingEvent event;
  const _ResultsView({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy\nHH:mm:ss', 'ru');

    final startDate = event.votingStartDate != null
        ? dateFormat.format(event.votingStartDate!)
        : 'Не установлено';
    final endDate = event.votingEndDate != null
        ? dateFormat.format(event.votingEndDate!)
        : 'Не установлено';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFE4DCC5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              event.title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Divider(),
            _InfoRow(label: 'Описание', value: event.description),
            _InfoRow(label: 'Начало\nголосования', value: startDate),
            _InfoRow(label: 'Завершение\nголосования', value: endDate),
            const SizedBox(height: 24),
            _ResultsTable(results: event.results),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Заседание завершено',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Виджет для всей секции с результатами
class _ResultsTable extends StatelessWidget {
  final List<QuestionResult> results;
  const _ResultsTable({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Text("Результаты для этого голосования отсутствуют.");
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D3BF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Результаты голосования',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          ...results.asMap().entries.map((entry) {
            int index = entry.key;
            QuestionResult questionResult = entry.value;
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${questionResult.name}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  // Оборачиваем таблицу в SingleChildScrollView для горизонтальной прокрутки
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildDataTable(context, questionResult),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, QuestionResult data) {
    List<String> columns;
    if (data.type == 'multiple_variants') {
      columns = ['Варианты ответов', 'Количество голосов'];
    } else {
      columns = ['', ...data.allColumns];
    }

    // FIXED: Все колонки теперь имеют ширину по своему содержимому
    Map<int, TableColumnWidth> columnWidths = {};
    for (int i = 0; i < columns.length; i++) {
      columnWidths[i] = const IntrinsicColumnWidth();
    }

    return Table(
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
          ),
          children: columns.map((colName) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                colName,
                textAlign: colName.isEmpty ? TextAlign.start : TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            );
          }).toList(),
        ),
        ...data.subjectResults.map((row) {
          return TableRow(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(row.name,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
              ...columns.sublist(1).map((colName) {
                String cellValue;
                if (data.type == 'multiple_variants') {
                  cellValue = (row.voteCounts[row.name] ?? 0).toString();
                } else {
                  cellValue = (row.voteCounts[colName] ?? 0).toString();
                }
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Center(child: Text(cellValue)),
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}

// Вспомогательный виджет для строк информации
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.black54)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}