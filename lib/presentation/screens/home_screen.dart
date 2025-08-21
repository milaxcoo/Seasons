import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/models.dart';
import '../bloc/voting/voting_bloc.dart';
import 'profile_screen.dart';
import 'results_screen.dart';
import 'voting_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch initial data for the first tab
    context
       .read<VotingBloc>()
       .add(const FetchEventsRequested(status: VotingEventStatus.registration));
    
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      switch (_tabController.index) {
        case 0:
          context.read<VotingBloc>().add(const FetchEventsRequested(status: VotingEventStatus.registration));
          break;
        case 1:
          context.read<VotingBloc>().add(const FetchEventsRequested(status: VotingEventStatus.active));
          break;
        case 2:
          context.read<VotingBloc>().add(const FetchEventsRequested(status: VotingEventStatus.completed));
          break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seasons Voting'),
        actions:,
        bottom: TabBar(
          controller: _tabController,
          tabs: const,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const,
      ),
    );
  }
}

class EventList extends StatelessWidget {
  final VotingEventStatus status;
  const EventList({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VotingBloc, VotingState>(
      builder: (context, state) {
        if (state is VotingLoadInProgress) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is VotingLoadSuccess) {
          final events = state.events.where((e) => e.status == status).toList();
          if (events.isEmpty) {
            return const Center(child: Text('No events found.'));
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return VotingEventCard(event: event);
            },
          );
        }
        if (state is VotingLoadFailure) {
          return Center(child: Text('Failed to load events: ${state.error}'));
        }
        return const Center(child: Text('Select a category to view events.'));
      },
    );
  }
}

class VotingEventCard extends StatelessWidget {
  final VotingEvent event;
  const VotingEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    String dateInfo;
    switch (event.status) {
      case VotingEventStatus.registration:
        dateInfo = 'Registration ends: ${dateFormat.format(event.registrationEndDate)}';
        break;
      case VotingEventStatus.active:
        dateInfo = 'Voting ends: ${dateFormat.format(event.votingEndDate)}';
        break;
      case VotingEventStatus.completed:
        dateInfo = 'Completed on: ${dateFormat.format(event.votingEndDate)}';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(dateInfo),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (event.status == VotingEventStatus.active) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VotingDetailsScreen(event: event),
            ));
          } else if (event.status == VotingEventStatus.completed) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ResultsScreen(event: event),
            ));
          } else {
            // For registration, can show a simple dialog or do nothing
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voting has not started for this event yet.')),
            );
          }
        },
      ),
    );
  }
}