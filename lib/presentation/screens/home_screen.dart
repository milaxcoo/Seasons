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
                child: Text(userLogin, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
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
                  shadows: [const Shadow(blurRadius: 10, color: Colors.black54)],
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            'времена года',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 8, color: Colors.black54)],
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w100,
                  fontSize: 16,
                  letterSpacing: 6,
                ),
          ),
        ],
      ),
    );
  }
}

class _PanelSelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onPanelSelected;
  final Map<model.VotingStatus, int> hasEvents;

  const _PanelSelector({
    required this.selectedIndex,
    required this.onPanelSelected,
    required this.hasEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _PanelButton(
            icon: RegistrationIcon(isSelected: selectedIndex == 0),
            isSelected: selectedIndex == 0,
            onTap: () => onPanelSelected(0),
            hasActiveEvents: hasEvents[model.VotingStatus.registration]! > 0,
          ),
          _PanelButton(
            icon: ActiveVotingIcon(isSelected: selectedIndex == 1),
            isSelected: selectedIndex == 1,
            onTap: () => onPanelSelected(1),
            hasActiveEvents: hasEvents[model.VotingStatus.active]! > 0,
          ),
          _PanelButton(
            icon: ResultsIcon(isSelected: selectedIndex == 2),
            isSelected: selectedIndex == 2,
            onTap: () => onPanelSelected(2),
            hasActiveEvents: hasEvents[model.VotingStatus.completed]! > 0,
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
                          _updateEventsCount([
                            model.VotingStatus.registration,
                            model.VotingStatus.active,
                            model.VotingStatus.completed,
                          ][_selectedPanelIndex], state.events.length);
                        }
                      },
                      child: _PanelSelector(
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
                        onRefresh: () => _fetchEventsForPanel(_selectedPanelIndex),
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

class _PanelButton extends StatelessWidget {
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasActiveEvents;

  const _PanelButton({
    required this.icon, 
    required this.isSelected, 
    required this.onTap,
    required this.hasActiveEvents,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    if (isSelected) {
      backgroundColor = Colors.white.withOpacity(0.9);
    } else if (hasActiveEvents) {
      backgroundColor = const Color(0xFF00A94F);
    } else {
      backgroundColor = const Color(0xFF6d9fc5);
    }

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 25,
        backgroundColor: backgroundColor,
        child: icon,
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
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Text(
            poem,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  height: 1.5,
                  shadows: [const Shadow(blurRadius: 6, color: Colors.black87)],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            author,
            textAlign: TextAlign.left,
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

  const _EventList({super.key, required this.status, required this.imagePath, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VotingBloc, VotingState>(
      builder: (context, state) {
        if (state is VotingLoadInProgress) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (state is VotingEventsLoadSuccess) {
          if (state.events.isEmpty) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 96),
              padding: const EdgeInsets.all(24),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    shadows: [const Shadow(blurRadius: 6, color: Colors.black87)],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          return Center(child: Text('Error: ${state.error}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)));
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      color: Colors.transparent,
      child: Container(
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
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListTile(
        title: Text(
          event.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [const Shadow(blurRadius: 4, color: Colors.black87)],
          ),
        ),
        subtitle: Text(
          dateInfo,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            shadows: [const Shadow(blurRadius: 4, color: Colors.black87)],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: () async {
          // --- DEBUG: Добавляем отладочные сообщения ---
          if (kDebugMode) {
            print('\n--- DEBUG [HomeScreen]: Нажата карточка "${event.title}" ---');
            print('--- DEBUG [HomeScreen]: Статус объекта event: ${event.status} ---');
          }

          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) {
                if (event.status == model.VotingStatus.registration) {
                  if (kDebugMode) print('--- DEBUG [HomeScreen]: Навигация -> RegistrationDetailsScreen ---');
                  return RegistrationDetailsScreen(event: event, imagePath: imagePath);
                } else if (event.status == model.VotingStatus.active) {
                  if (kDebugMode) print('--- DEBUG [HomeScreen]: Навигация -> VotingDetailsScreen ---');
                  return VotingDetailsScreen(event: event, imagePath: imagePath);
                } else { // Это должен быть completed
                  if (kDebugMode) print('--- DEBUG [HomeScreen]: Навигация -> ResultsScreen ---');
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
      ),
    );
  }
}

