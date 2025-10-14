import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/widgets/app_background.dart';

class RegistrationDetailsScreen extends StatelessWidget {
  final model.VotingEvent event;
  // FIXED: Добавлено поле для получения пути к фону
  final String imagePath;

  const RegistrationDetailsScreen({
    super.key, 
    required this.event,
    required this.imagePath, // Сделано обязательным параметром
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VotingBloc(
        votingRepository: RepositoryProvider.of<VotingRepository>(context),
      ),
      // FIXED: Используем переданный imagePath
      child: AppBackground(
        imagePath: imagePath,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.2),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Детали события',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
            ),
            body: _RegistrationDetailsView(event: event),
          ),
        ),
      ),
    );
  }
}

class _RegistrationDetailsView extends StatelessWidget {
  final model.VotingEvent event;
  const _RegistrationDetailsView({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd('ru');

    // BlocListener отслеживает изменения состояния для выполнения действий (например, показ уведомления).
    return BlocListener<VotingBloc, VotingState>(
      listener: (context, state) {
        if (state is RegistrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Вы были успешно зарегистрированы!'), backgroundColor: Colors.green),
          );
          // Возвращаемся на предыдущий экран после успешной регистрации.
          Navigator.of(context).pop();
        }
        if (state is RegistrationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка регистрации: ${state.error}'), backgroundColor: Colors.red),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              event.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Описание
            Text(
              event.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.9), height: 1.5),
            ),
            const Spacer(), // Занимает все свободное место, прижимая контент ниже к низу
            // Даты
            _InfoRow(
              icon: Icons.event_available,
              label: 'Регистрация до:',
              value: dateFormat.format(event.registrationEndDate),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.how_to_vote,
              label: 'Голосование с:',
              value: dateFormat.format(event.votingStartDate),
            ),
            const SizedBox(height: 32),
            // Кнопка регистрации с BlocBuilder
            SizedBox(
              width: double.infinity,
              child: BlocBuilder<VotingBloc, VotingState>(
                builder: (context, state) {
                  // Если идет регистрация, показываем индикатор загрузки.
                  if (state is RegistrationInProgress) {
                    return ElevatedButton(
                      onPressed: null, // Кнопка неактивна во время загрузки
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  // В остальных случаях показываем кнопку, зависящую от статуса регистрации.
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      // Если уже зарегистрирован, делаем кнопку серой.
                      backgroundColor: event.isRegistered ? Colors.grey : Theme.of(context).colorScheme.primary,
                    ),
                    // Если уже зарегистрирован, отключаем кнопку.
                    onPressed: event.isRegistered ? null : () {
                      // При нажатии отправляем событие в BLoC.
                      context.read<VotingBloc>().add(RegisterForEvent(eventId: event.id));
                    },
                    child: Text(
                      // Меняем текст на кнопке в зависимости от статуса регистрации.
                      event.isRegistered ? 'Вы уже зарегистрированы' : 'Зарегистрироваться',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Вспомогательный виджет для отображения строк информации.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

