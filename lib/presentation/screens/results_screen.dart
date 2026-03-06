import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seasons/core/layout/adaptive_layout.dart';
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
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: _ResultsView(event: event),
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
    final detailStyle = context.adaptiveLayout.detailLayoutStyle;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: detailStyle.outerPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: detailStyle.maxContentWidth),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE4DCC5).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(detailStyle.cardPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        event.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: detailStyle.titleFontSize,
                            ),
                      ),
                      SizedBox(height: detailStyle.sectionGap),
                      const Divider(color: Colors.grey, height: 1),
                      SizedBox(height: detailStyle.sectionGap),
                      if (event.description.isNotEmpty) ...[
                        Text(
                          event.description,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: detailStyle.sectionGap),
                        const Divider(color: Colors.grey, height: 1),
                        SizedBox(height: detailStyle.sectionGap),
                      ],
                      _InfoRow(
                        label: l10n.votingStartLabel,
                        value: startDate,
                        style: detailStyle,
                      ),
                      SizedBox(height: detailStyle.sectionGap),
                      const Divider(color: Colors.grey, height: 1),
                      SizedBox(height: detailStyle.sectionGap),
                      _InfoRow(
                        label: l10n.votingEndLabel,
                        value: endDate,
                        style: detailStyle,
                      ),
                      SizedBox(height: detailStyle.sectionGapLarge),
                      _ResultsTable(results: event.results, style: detailStyle),
                      SizedBox(height: detailStyle.sectionGapLarge),
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: detailStyle.actionVerticalPadding,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(26),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Виджет для всей секции с результатами
class _ResultsTable extends StatelessWidget {
  final List<QuestionResult> results;
  final AdaptiveDetailLayoutStyle style;
  const _ResultsTable({required this.results, required this.style});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (results.isEmpty) {
      return Text(l10n.resultsUnavailable);
    }

    final containerPadding = EdgeInsets.symmetric(
      horizontal: style.cardPadding +
          (style.isExtremeCompact ? 0.0 : style.sectionGapSmall),
      vertical: style.cardPadding +
          (style.isExtremeCompact ? 0.0 : style.sectionGapSmall),
    );

    return Container(
      padding: containerPadding,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D3BF),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.votingResults,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: style.isExtremeCompact ? null : 18,
                ),
          ),
          SizedBox(height: style.sectionGapSmall + 4),
          const Divider(),
          SizedBox(height: style.sectionGapSmall + 4),
          ...results.asMap().entries.map((entry) {
            int index = entry.key;
            QuestionResult questionResult = entry.value;
            return Padding(
              padding: EdgeInsets.only(top: style.sectionGapLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${questionResult.name}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: style.isExtremeCompact ? null : 16,
                        ),
                  ),
                  SizedBox(height: style.sectionGap),
                  _buildDataTable(context, questionResult, l10n),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    QuestionResult data,
    AppLocalizations l10n,
  ) {
    // Определяем колонки
    List<String> columns;
    if (data.type == 'qualification_council') {
      // Для qualification_council структура специфичная, но по сути 2 колонки
      columns = ['', l10n.voteCount];
    } else if (data.type == 'multiple_variants') {
      columns = ['', l10n.voteCount];
    } else {
      columns = ['', ...data.allColumns];
    }

    final int colCount = columns.length;

    // --- ЛОГИКА РАСЧЕТА ШИРИНЫ КОЛОНОК ---
    // Use flexible widths so the table always fits without horizontal scroll.
    // First column (subject name) gets ~50%, data columns share the rest equally.
    final Map<int, TableColumnWidth> tableColumnWidths = {
      0: const FlexColumnWidth(3),
    };
    for (int i = 1; i < colCount; i++) {
      tableColumnWidths[i] = const FlexColumnWidth(2);
    }

    // --- ВИЗУАЛЬНЫЕ НАСТРОЙКИ ---
    // Portrait: more spacious cells
    final cellPadding = EdgeInsets.symmetric(
      horizontal: style.tableCellHorizontalPadding,
      vertical: style.tableCellVerticalPadding,
    );

    // Вспомогательная функция для ячейки
    Widget buildCell(
      String text, {
      bool isHeader = false,
      bool alignCenter = false,
    }) {
      return Padding(
        padding: cellPadding,
        child: Text(
          text,
          textAlign: alignCenter ? TextAlign.center : TextAlign.start,
          style: isHeader
              ? Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)
              : Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    // --- СБОРКА ТАБЛИЦЫ ---
    Widget tableContent;

    if (data.type == 'qualification_council') {
      tableContent = Table(
        border: TableBorder(
          verticalInside: BorderSide(
            color: Colors.black.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        columnWidths: tableColumnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Заголовок
          TableRow(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
            ),
            children: [
              buildCell('', isHeader: true),
              buildCell(l10n.voteCount, isHeader: true, alignCenter: true),
            ],
          ),
          // Строки
          ...data.subjectResults.expand((subject) {
            return subject.voteCounts.entries.map((entry) {
              return TableRow(
                children: [
                  buildCell(subject.name),
                  Padding(
                    padding: cellPadding,
                    child: Center(child: Text(entry.value.toString())),
                  ),
                ],
              );
            });
          }),
        ],
      );
    } else {
      // Стандартная таблица
      tableContent = Table(
        border: TableBorder(
          verticalInside: BorderSide(
            color: Colors.black.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        columnWidths: tableColumnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Заголовок
          TableRow(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
            ),
            children: columns.map((colName) {
              return buildCell(
                colName,
                isHeader: true,
                alignCenter: colName.isNotEmpty,
              );
            }).toList(),
          ),
          // Строки
          ...data.subjectResults.map((row) {
            return TableRow(
              children: [
                buildCell(row.name),
                ...columns.sublist(1).map((colName) {
                  String cellValue;
                  if (data.type == 'multiple_variants') {
                    cellValue = (row.voteCounts[row.name] ?? 0).toString();
                  } else {
                    cellValue = (row.voteCounts[colName] ?? 0).toString();
                  }
                  return Padding(
                    padding: cellPadding,
                    child: Center(child: Text(cellValue)),
                  );
                }),
              ],
            );
          }),
        ],
      );
    }

    return tableContent;
  }
}

// Вспомогательный виджет для строк информации
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AdaptiveDetailLayoutStyle style;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack =
            style.isExtremeCompact || constraints.maxWidth < 350;
        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
              SizedBox(height: style.sectionGapSmall),
              Text(
                value,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: style.rowLabelWidth,
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
            ),
            SizedBox(width: style.rowGap),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        );
      },
    );
  }
}
