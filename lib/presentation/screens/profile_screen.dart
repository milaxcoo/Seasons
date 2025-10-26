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
    final theme = monthlyThemes[currentMonth] ?? monthlyThemes[10]!; // Октябрь по умолчанию

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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _UserInfoRow(
                  label: 'Фамилия',
                  value: 'Лебедев',
                ),
                const SizedBox(height: 24),
                _UserInfoRow(
                  label: 'Имя',
                  value: 'Михаил',
                ),
                const SizedBox(height: 24),
                _UserInfoRow(
                  label: 'Отчество',
                  value: 'Александрович',
                ),
                const SizedBox(height: 24),
                _UserInfoRow(
                  label: 'Электронная почта',
                  value: 'lebedev_ma@pfur.ru',
                ),
                const SizedBox(height: 24),
                _UserInfoRow(
                  label: 'Должность',
                  value: 'Студент', // Это значение можно будет получать из API в будущем
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        // Метка (например, "Фамилия")
        SizedBox(
          width: 120, // Фиксированная ширина для выравнивания
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
          ),
        ),
        const SizedBox(width: 24),
        // Значение (например, "Лебедев")
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}

