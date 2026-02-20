import 'dart:math';
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

    // FIXED: Standardized scrollable area style (Window with internal scroll)
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return SafeArea(
      child: Center(
        child: Padding(
          // Responsive padding: Smaller margins in landscape to maximize card size
          padding: isLandscape 
              ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0)
              : const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE4DCC5),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), // Subtle shadow
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24), // Inner padding for content
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Shrink to fit content if small
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
        borderRadius: BorderRadius.circular(26),
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
                  // Таблица сама управляет своим скроллом внутри LayoutBuilder
                  _buildDataTable(context, questionResult, l10n),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, QuestionResult data, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;

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
        // 1. Первая колонка (Имя субъекта) - 40% от ширины, но не меньше 160 и не больше 320
        final double firstColWidth = (availableWidth * 0.40).clamp(160.0, 320.0);

        // 2. Остальные колонки (данные)
        final int dataColsCount = max(1, colCount - 1);
        final double minDataColWidth = 96.0;
        final double remainingWidth = availableWidth - firstColWidth;

        // Ширина колонки данных: либо доля остатка, либо минимум (если остаток слишком мал)
        final double dataColWidth = max(minDataColWidth, remainingWidth / dataColsCount);

        // 3. Общая ширина таблицы
        final double totalTableWidth = firstColWidth + (dataColWidth * dataColsCount);

        // 4. Формируем карту ширины колонок для Table
        final Map<int, TableColumnWidth> tableColumnWidths = {
          0: FixedColumnWidth(firstColWidth),
        };
        for (int i = 1; i < colCount; i++) {
          tableColumnWidths[i] = FixedColumnWidth(dataColWidth);
        }

        // --- ВИЗУАЛЬНЫЕ НАСТРОЙКИ ---
        const cellPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

        // Вспомогательная функция для ячейки
        Widget buildCell(String text, {bool isHeader = false, bool alignCenter = false}) {
          return Padding(
            padding: cellPadding,
            child: Text(
              text,
              textAlign: alignCenter ? TextAlign.center : TextAlign.start,
              style: isHeader
                  ? Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w900)
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
                  return buildCell(colName,
                      isHeader: true, alignCenter: colName.isNotEmpty);
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

        // Возвращаем скроллируемый контейнер с ограниченной минимальной шириной
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: max(availableWidth, totalTableWidth)),
            child: tableContent,
          ),
        );
      },
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
