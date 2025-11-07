import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:seasons/core/monthly_theme_data.dart'; // Импортируем наш файл с темами
import 'package:seasons/presentation/widgets/app_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем тему для текущего месяца
    final currentMonth = DateTime.now().month;
    final theme = monthlyThemes[currentMonth] ??
        monthlyThemes[10]!; // Октябрь по умолчанию

    return AppBackground(
        imagePath: theme.imagePath, // Используем динамический фон
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.25),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Данные пользователя',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge // Используем 'bodyLarge' (Exo 2 w700)
                    ?.copyWith(
                      color: Colors.white,
                      fontSize: 20, // Делаем крупнее
                      fontWeight: FontWeight.w900, // Делаем жирнее
                    ),
              ),
            ),
            body: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE4DCC5).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _UserInfoRow(
                      label: 'Фамилия',
                      value: 'Лебедев',
                    ),
                    const Divider(height: 24),
                    _UserInfoRow(
                      label: 'Имя',
                      value: 'Михаил',
                    ),
                    const Divider(height: 24),
                    _UserInfoRow(
                      label: 'Отчество',
                      value: 'Александрович',
                    ),
                    const Divider(height: 24),
                    _UserInfoRow(
                      label: 'Электронная почта',
                      value: 'lebedev_ma@pfur.ru',
                    ),
                    const Divider(height: 24),
                    _UserInfoRow(
                      label: 'Должность',
                      value: 'Студент',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}

// Вспомогательный виджет для отображения строк с информацией
class _UserInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _UserInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyLarge // Используем 'bodyLarge' (Exo 2 w700)
                ?.copyWith(
                  color: Colors.black,
                ),
          ),
        ),
      ],
    );
  }
}