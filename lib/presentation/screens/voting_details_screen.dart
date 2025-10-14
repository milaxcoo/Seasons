import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/widgets/app_background.dart';

class VotingDetailsScreen extends StatelessWidget {
  final model.VotingEvent event;
  // FIXED: Добавлено поле для получения пути к фону
  final String imagePath;

  const VotingDetailsScreen({
    super.key, 
    required this.event,
    required this.imagePath, // Сделано обязательным параметром
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VotingBloc(
        votingRepository: RepositoryProvider.of<VotingRepository>(context),
      )..add(FetchNominees(eventId: event.id)), // Сразу запрашиваем номинантов
      child: AppBackground(
        imagePath: imagePath, // FIXED: Используем переданный imagePath
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.2),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
            ),
            body: _VotingDetailsView(event: event),
          ),
        ),
      ),
    );
  }
}

class _VotingDetailsView extends StatefulWidget {
  final model.VotingEvent event;
  const _VotingDetailsView({required this.event});

  @override
  State<_VotingDetailsView> createState() => _VotingDetailsViewState();
}

class _VotingDetailsViewState extends State<_VotingDetailsView> {
  String? _selectedNomineeId;
  bool _voteSubmitted = false;

  void _submitVote() {
    if (_selectedNomineeId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Пожалуйста, выберите номинанта перед отправкой.'),
          backgroundColor: Colors.orange,
        ));
      return;
    }
    context.read<VotingBloc>().add(
          SubmitVote(
            eventId: widget.event.id,
            nomineeId: _selectedNomineeId!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VotingBloc, VotingState>(
      listener: (context, state) {
        if (state is VotingSubmissionSuccess) {
          setState(() {
            _voteSubmitted = true;
          });
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Голос принят'),
              content: const Text('Спасибо за участие!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (state is VotingFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text('Ошибка: ${state.error}'),
              backgroundColor: Colors.redAccent,
            ));
        }
      },
      builder: (context, state) {
        // Показываем индикатор загрузки, пока не загрузятся номинанты
        if (state is VotingLoadInProgress && !_voteSubmitted) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        // Когда номинанты загружены, показываем список
        if (state is VotingNomineesLoadSuccess) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: state.nominees.length,
                  itemBuilder: (context, index) {
                    final nominee = state.nominees[index];
                    return Card(
                      color: Colors.black.withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: RadioListTile<String>(
                        title: Text(
                          nominee.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                        value: nominee.id,
                        groupValue: _selectedNomineeId,
                        activeColor: Colors.white,
                        onChanged: _voteSubmitted
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedNomineeId = value;
                                });
                              },
                      ),
                    );
                  },
                ),
              ),
              // Кнопка "Проголосовать"
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: (_selectedNomineeId == null || _voteSubmitted)
                        ? null
                        : _submitVote,
                    child: Text(
                      _voteSubmitted ? 'Голос принят' : 'Проголосовать',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        if (state is VotingFailure) {
          return Center(
            child: Text(
              'Не удалось загрузить номинантов: ${state.error}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          );
        }
        // После успешного голосования, пока не произошел pop, показываем загрузчик
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      },
    );
  }
}

