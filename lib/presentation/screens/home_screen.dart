import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:seasons/core/monthly_theme_data.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/screens/login_screen.dart';
import 'package:seasons/presentation/screens/profile_screen.dart';
import 'package:seasons/presentation/screens/registration_details_screen.dart';
import 'package:seasons/presentation/screens/results_screen.dart';
import 'package:seasons/presentation/screens/voting_details_screen.dart';
import 'package:seasons/presentation/widgets/app_background.dart';
import 'package:seasons/presentation/widgets/custom_icons.dart';
import 'package:seasons/presentation/widgets/v_menu.dart';

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userLogin = 'User';
    if (authState is AuthAuthenticated) {
      userLogin = authState.userLogin;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Text(userLogin,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white)),
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                onPressed: () {
                  context.read<AuthBloc>().add(LoggedOut());
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          Text(
            'Seasons',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(blurRadius: 10, color: Colors.black54),
                    const Shadow(
                        blurRadius: 2,
                        color: Colors.black87) // <-- ДОБАВЛЕНО
                  ],
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            'времена года',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  shadows: [
                    const Shadow(blurRadius: 8, color: Colors.black54),
                    const Shadow(
                        blurRadius: 2,
                        color: Colors.black54) // <-- ДОБАВЛЕНО
                  ],
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 7,
                ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedPanelIndex = 0;
  final Map<model.VotingStatus, int> _eventsCount = {
    model.VotingStatus.registration: 0,
    model.VotingStatus.active: 0,
    model.VotingStatus.completed: 0,
  };

  void _updateEventsCount(model.VotingStatus status, int count) {
    setState(() {
      _eventsCount[status] = count;
    });
  }

  void _fetchEventsForPanel(int index) {
    setState(() {
      _selectedPanelIndex = index;
    });
    final status = [
      model.VotingStatus.registration,
      model.VotingStatus.active,
      model.VotingStatus.completed,
    ][_selectedPanelIndex];
    context.read<VotingBloc>().add(FetchEventsByStatus(status: status));
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;
    final theme = monthlyThemes[currentMonth] ?? monthlyThemes[10]!;
    return AppBackground(
      imagePath: theme.imagePath,
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
          Positioned.fill(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Column(
                  children: [
                    _TopBar(),
                    _Header(),
                    BlocListener<VotingBloc, VotingState>(
                      listener: (context, state) {
                        if (state is VotingEventsLoadSuccess) {
                          _updateEventsCount(
                              [
                                model.VotingStatus.registration,
                                model.VotingStatus.active,
                                model.VotingStatus.completed,
                              ][_selectedPanelIndex],
                              state.events.length);
                        }
                      },
                      child: VMenu(
                        selectedIndex: _selectedPanelIndex,
                        onPanelSelected: _fetchEventsForPanel,
                        hasEvents: _eventsCount,
                      ),
                    ),
                    Expanded(
                      child: _EventList(
                        key: ValueKey(_selectedPanelIndex),
                        status: [
                          model.VotingStatus.registration,
                          model.VotingStatus.active,
                          model.VotingStatus.completed,
                        ][_selectedPanelIndex],
                        imagePath: theme.imagePath,
                        onRefresh: () =>
                            _fetchEventsForPanel(_selectedPanelIndex),
                      ),
                    ),
                    _Footer(poem: theme.poem, author: theme.author),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final String poem;
  final String author;

  const _Footer({required this.poem, required this.author});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poem,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              height: 1.5,
              shadows: [const Shadow(blurRadius: 6, color: Colors.black87)],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            author,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              shadows: [const Shadow(blurRadius: 6, color: Colors.black87)],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final model.VotingStatus status;
  final String imagePath;
  final VoidCallback onRefresh;

  const _EventList(
      {super.key,
      required this.status,
      required this.imagePath,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VotingBloc, VotingState>(
      builder: (context, state) {
        if (state is VotingLoadInProgress) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (state is VotingEventsLoadSuccess) {
          if (state.events.isEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 72.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  'Нет активных голосований',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 20.0,
                        shadows: [
                          const Shadow(blurRadius: 6, color: Colors.black87)
                        ],
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: state.events.length,
            itemBuilder: (context, index) {
              return _VotingEventCard(
                event: state.events[index],
                imagePath: imagePath,
                onActionComplete: onRefresh,
              );
            },
          );
        }
        if (state is VotingFailure) {
          return Center(
              child: Text('Error: ${state.error}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white)));
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _VotingEventCard extends StatelessWidget {
  final model.VotingEvent event;
  final String imagePath;
  final VoidCallback onActionComplete;

  const _VotingEventCard({
    required this.event,
    required this.imagePath,
    required this.onActionComplete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd('ru');
    String dateInfo;

    switch (event.status) {
      case model.VotingStatus.registration:
        dateInfo = event.registrationEndDate != null
            ? 'Регистрация до: ${dateFormat.format(event.registrationEndDate!)}'
            : 'Регистрация открыта';
        break;
      case model.VotingStatus.active:
        dateInfo = event.votingEndDate != null
            ? 'Голосование до: ${dateFormat.format(event.votingEndDate!)}'
            : 'Голосование активно';
        break;
      case model.VotingStatus.completed:
        dateInfo = event.votingEndDate != null
            ? 'Завершено: ${dateFormat.format(event.votingEndDate!)}'
            : 'Завершено';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: const Color(0xFFE4DCC5),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            event.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                ),
                
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateInfo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            if (event.status == model.VotingStatus.registration ||
                event.status == model.VotingStatus.active) ...[
              const SizedBox(height: 2),
              Text(
                event.status == model.VotingStatus.registration ? (event.isRegistered ? "Зарегистрирован(-а)" : "Не зарегистрирован(-а)") : (event.hasVoted ? "Проголосовал(-а)" : "Не проголосовал(-а)"),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: (event.status == model.VotingStatus.registration
                              ? event.isRegistered
                              : event.hasVoted)
                          ? const Color(0xFF00A94F)
                          : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black54),
        onTap: () async {
          if (kDebugMode) {
            print(
                '\n--- DEBUG [HomeScreen]: Нажата карточка "${event.title}" ---');
            print(
                '--- DEBUG [HomeScreen]: Статус объекта event: ${event.status} ---');
          }

          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) {
                if (event.status == model.VotingStatus.registration) {
                  if (kDebugMode) {
                    print(
                        '--- DEBUG [HomeScreen]: Навигация -> RegistrationDetailsScreen ---');
                  }
                  return RegistrationDetailsScreen(
                      event: event, imagePath: imagePath);
                } else if (event.status == model.VotingStatus.active) {
                  if (kDebugMode) {
                    print(
                        '--- DEBUG [HomeScreen]: Навигация -> VotingDetailsScreen ---');
                  }
                  return VotingDetailsScreen(
                      event: event, imagePath: imagePath);
                } else {
                  if (kDebugMode) {
                    print(
                        '--- DEBUG [HomeScreen]: Навигация -> ResultsScreen ---');
                  }
                  return ResultsScreen(event: event, imagePath: imagePath);
                }
              },
            ),
          );

          if (result == true) {
            onActionComplete();
          }
        },
      ),
    );
  }
}