import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/widgets/app_background.dart';
import 'package:seasons/l10n/app_localizations.dart';

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
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.35),
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
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('dd.MM.yyyy\nHH:mm:ss', localeName);

    final startDate = event.votingStartDate != null
        ? dateFormat.format(event.votingStartDate!)
        : l10n.notSet;
    final endDate = event.votingEndDate != null
        ? dateFormat.format(event.votingEndDate!)
        : l10n.notSet;

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
            Text(
              event.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            const Divider(),
            _InfoRow(label: l10n.votingStartLabel, value: startDate),
            _InfoRow(label: l10n.votingEndLabel, value: endDate),
            const SizedBox(height: 24),
            _ResultsTable(results: event.results),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  l10n.sessionCompleted,
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
    final l10n = AppLocalizations.of(context)!;
    if (results.isEmpty) {
      return Text(l10n.resultsUnavailable);
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
            l10n.votingResults,
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
                    child: _buildDataTable(context, questionResult, l10n),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, QuestionResult data, AppLocalizations l10n) {
    // Для qualification_council показываем варианты ответов как строки, а не колонки
    if (data.type == 'qualification_council') {
      return Table(
        border: TableBorder(
          verticalInside: BorderSide(
            color: Colors.black.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: IntrinsicColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Заголовок таблицы
          TableRow(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  '',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  l10n.voteCount,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          // Строки с данными - каждая комбинация субъект-ответ это отдельная строка
          ...data.subjectResults.expand((subject) {
            return subject.voteCounts.entries.map((entry) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      subject.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Center(
                      child: Text(entry.value.toString()),
                    ),
                  ),
                ],
              );
            });
          }),
        ],
      );
    }

    // Для остальных типов (yes_no, yes_no_abstained, multiple_variants, subject_oriented)
    List<String> columns;
    if (data.type == 'multiple_variants') {
      columns = ['', l10n.voteCount];
    } else {
      columns = ['', ...data.allColumns];
    }

    Map<int, TableColumnWidth> columnWidths = {};
    for (int i = 0; i < columns.length; i++) {
      columnWidths[i] = const IntrinsicColumnWidth();
    }

    return Table(
      border: TableBorder(
        verticalInside: BorderSide(
          color: Colors.black.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
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
