import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/screens/profile_screen.dart';
import 'package:seasons/presentation/screens/result_screen.dart';
import 'package:seasons/presentation/screens/voting_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Use SingleTickerProviderStateMixin to provide the Ticker for the TabController animation.
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Fetch initial data for the first tab ("Registration") when the screen loads.
    _fetchEventsForTab(0);

    // Add a listener to the TabController to fetch data when the user switches tabs.
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchEventsForTab(_tabController.index);
      }
    });
  }

  void _fetchEventsForTab(int index) {
    // Map the tab index to the corresponding VotingStatus and dispatch the event.
    final status = [
      model.VotingStatus.registration,
      model.VotingStatus.active,
      model.VotingStatus.completed,
    ][index];
    // This line now correctly creates an instance of the event
    // and adds it to the BLoC, resolving the 'undefined_method' error.
    context.read<VotingBloc>().add(FetchEventsByStatus(status: status));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/august.jpg"), // Assumes background image is set
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Make AppBar transparent
          title: Text(
            'Seasons',
            // FIXED: Explicitly apply the Russo One font to the AppBar title.
            style: GoogleFonts.russoOne(
              textStyle: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
          actions: [
            // Button to navigate to the ProfileScreen.
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
          // The TabBar is placed in the bottom of the AppBar.
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Registration'),
              Tab(text: 'Active'),
              Tab(text: 'Results'),
            ],
          ),
        ),
        // TabBarView displays the content for the currently selected tab.
        body: TabBarView(
          controller: _tabController,
          children: const [
            _EventList(status: model.VotingStatus.registration),
            _EventList(status: model.VotingStatus.active),
            _EventList(status: model.VotingStatus.completed),
          ],
        ),
      ),
    );
  }
}

// A reusable widget to display a list of events for a given status.
class _EventList extends StatelessWidget {
  final model.VotingStatus status;
  const _EventList({required this.status});

  @override
  Widget build(BuildContext context) {
    // BlocBuilder rebuilds the UI in response to VotingState changes.
    return BlocBuilder<VotingBloc, VotingState>(
      builder: (context, state) {
        if (state is VotingLoadInProgress) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is VotingEventsLoadSuccess) {
          // Filter the events from the state to match the status for this list.
          final events = state.events.where((e) => e.status == status).toList();
          if (events.isEmpty) {
            return Center(
                child: Text('No events found for this category.',
                    style: GoogleFonts.russoOne(color: Colors.white)));
          }
          // Use ListView.builder for efficient rendering of long lists.
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _VotingEventCard(event: events[index]);
            },
          );
        }
        if (state is VotingFailure) {
          return Center(
              child: Text('Error: ${state.error}',
                  style: GoogleFonts.russoOne(color: Colors.white)));
        }
        // Initial or default state.
        return Center(
            child: Text('Loading events...',
                style: GoogleFonts.russoOne(color: Colors.white)));
      },
    );
  }
}

// A reusable widget to display a single voting event in a Card.
class _VotingEventCard extends StatelessWidget {
  final model.VotingEvent event;
  const _VotingEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    // Use the intl package for user-friendly date formatting.
    final dateFormat = DateFormat.yMMMd();
    String dateInfo;

    // Determine the appropriate date text based on the event's status.
    switch (event.status) {
      case model.VotingStatus.registration:
        dateInfo =
            'Registration Ends: ${dateFormat.format(event.registrationEndDate)}';
        break;
      case model.VotingStatus.active:
        dateInfo = 'Voting Ends: ${dateFormat.format(event.votingEndDate)}';
        break;
      case model.VotingStatus.completed:
        dateInfo = 'Completed: ${dateFormat.format(event.votingEndDate)}';
        break;
    }

    return Card(
      color: const Color(0xFFe4dcc5), // FIXED: Changed the card color
      child: ListTile(
        title:
            Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(dateInfo),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to the correct screen based on the event's status.
          if (event.status == model.VotingStatus.active) {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => VotingDetailsScreen(event: event)),
            );
          } else if (event.status == model.VotingStatus.completed) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ResultsScreen(event: event)),
            );
          } else {
            // For registration events, show a simple SnackBar.
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                    content: Text('Voting has not started for this event.')),
              );
          }
        },
      ),
    );
  }
}
