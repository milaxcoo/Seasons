import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/widgets/app_background.dart';


class RegistrationDetailsScreen extends StatelessWidget {
  final model.VotingEvent event;

  const RegistrationDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd('ru');

    return AppBackground(
      imagePath: 'assets/august.jpg', // Or pass this dynamically if needed
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          color: Colors.black.withOpacity(0.2), // Optional: darken the background
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Детали события',
                style: GoogleFonts.russoOne(color: Colors.white),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title
                  Text(
                    event.title,
                    style: GoogleFonts.russoOne(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Event Description
                  Text(
                    event.description,
                    style: GoogleFonts.russoOne(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(), // Pushes the following content to the bottom

                  // Key Dates
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

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        // Placeholder for registration logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Вы были успешно зарегистрированы!')),
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Зарегистрироваться',
                        style: GoogleFonts.russoOne(fontSize: 18, color: Colors.white),
                      ),
                    ),
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

// A small helper widget for displaying info rows
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
        Text(
          label,
          style: GoogleFonts.russoOne(fontSize: 16, color: Colors.white70),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.russoOne(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
