import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:seasons/presentation/widgets/app_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = {
      'Фамилия': 'Лебедев',
      'Имя': 'Михаил',
      'Отчество': 'Александрович',
      'Электронная почта': 'lebedev_ma@pfur.ru',
      'Должность': 'Студент',
    };

    return AppBackground(
      imagePath: 'assets/august.jpg',
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                'Данные пользователя',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Create a list of user info rows from the map data
                  ...userData.entries.map((entry) {
                    return _UserInfoRow(
                      label: entry.key,
                      value: entry.value,
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// A reusable widget for displaying a single row of user information.
class _UserInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _UserInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label column
          SizedBox(
            width: 120, // Fixed width for the label column for alignment
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w100,
                  ),
            ),
          ),
          const SizedBox(width: 24),
          // Value column (expands to fill the remaining space)
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
