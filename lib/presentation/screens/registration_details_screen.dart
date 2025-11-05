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
  final String imagePath;

  const RegistrationDetailsScreen({
    super.key,
    required this.event,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VotingBloc(
        votingRepository: RepositoryProvider.of<VotingRepository>(context),
      ),
      child: AppBackground(
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
                body: _RegistrationDetailsView(event: event),
              ),
            ),
          ],
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
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss', 'ru');
    
    final startDate = event.votingStartDate != null 
        ? dateFormat.format(event.votingStartDate!) 
        : 'Не установлено';
        
    final endDate = event.registrationEndDate != null 
        ? dateFormat.format(event.registrationEndDate!) 
        : 'Не установлено';

    return BlocListener<VotingBloc, VotingState>(
      listener: (context, state) {
        if (state is RegistrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Вы были успешно зарегистрированы!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }
        if (state is RegistrationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка регистрации: ${state.error}'), backgroundColor: Colors.red),
          );
        }
      },
      // FIXED: Поменяли местами Center и SingleChildScrollView и добавили SafeArea
      child: SafeArea( // Добавили SafeArea, чтобы контент не залезал под "челку"
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0), // Перенесли отступ сюда
            child: Container(
              // margin убран, так как padding теперь снаружи
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE4DCC5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    event.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  _InfoRow(label: 'Начало\nрегистрации', value: startDate),
                  const Divider(),
                  _InfoRow(label: 'Завершение\nрегистрации', value: endDate),
                  const Divider(),
                  _InfoRow(
                    label: 'Статус',
                    value: event.isRegistered ? 'Зарегистрирован' : 'Не зарегистрирован',
                    valueColor: event.isRegistered ? const Color(0xFF00A94F) : Colors.red,
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<VotingBloc, VotingState>(
                    builder: (context, state) {
                      if (state is RegistrationInProgress) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Идет регистрация...',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                            ),
                          ),
                        );
                      }
                      
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          side: BorderSide(color: event.isRegistered ? Colors.grey : const Color(0xFF6A9457), width: 2),
                          backgroundColor: event.isRegistered ? Colors.grey.shade300 : Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: event.isRegistered ? null : () {
                          context.read<VotingBloc>().add(RegisterForEvent(eventId: event.id));
                        },
                        child: Text(
                          event.isRegistered ? 'Вы уже зарегистрированы' : 'Зарегистрироваться',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: event.isRegistered ? Colors.black54 : const Color(0xFF6A9457),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}