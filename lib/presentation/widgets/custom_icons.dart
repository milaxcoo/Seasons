import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// A base class to handle the color logic for the SVG icons.
abstract class _SvgIcon extends StatelessWidget {
  final bool isSelected;
  final String svgData;

  const _SvgIcon({super.key, required this.isSelected, required this.svgData});

  @override
  Widget build(BuildContext context) {
    // The color is determined by the isSelected flag.
    final color = isSelected ? Colors.black87 : Colors.white;
    return SvgPicture.string(
      svgData,
      width: 30,
      height: 30,
      // This filter finds "currentColor" in the SVG and replaces it with our desired color.
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

// Icon for the "Registration" panel.
class RegistrationIcon extends _SvgIcon {
  const RegistrationIcon({super.key, required super.isSelected})
      : super(
          svgData: '''
            <svg viewBox="0 0 24 24">
              <path stroke="currentColor" stroke-width="2" stroke-linecap="round" fill="none" d="M3.8,6.6h16.4"></path>
              <path stroke="currentColor" stroke-width="2" stroke-linecap="round" fill="none" d="M20.2,12.1H3.8"></path>
              <path stroke="currentColor" stroke-width="2" stroke-linecap="round" fill="none" d="M3.8,17.5h16.4"></path>
            </svg>
          ''',
        );
}

// Icon for the "Active Voting" panel.
class ActiveVotingIcon extends _SvgIcon {
  const ActiveVotingIcon({super.key, required super.isSelected})
      : super(
          svgData: '''
            <svg viewBox="0 0 24 24">
              <path stroke="currentColor" stroke-width="2" stroke-linecap="round" fill="none" d="M6.7,4.8h10.7c0.3,0,0.6,0.2,0.7,0.5l2.8,7.3c0,0.1,0,0.2,0,0.3v5.6c0,0.4-0.4,0.8-0.8,0.8H3.8c-0.4,0-0.8-0.3-0.8-0.8v-5.6c0-0.1,0-0.2,0.1-0.3L6,5.3C6.1,5,6.4,4.8,6.7,4.8z"></path>
              <path stroke="currentColor" stroke-width="2" stroke-linecap="round" fill="none" d="M3.4,12.9H8l1.6,2.8h4.9l1.5-2.8h4.6"></path>
            </svg>
          ''',
        );
}

// Icon for the "Results" panel.
class ResultsIcon extends _SvgIcon {
  const ResultsIcon({super.key, required super.isSelected})
      : super(
          svgData: '''
            <svg viewBox="0 0 24 24">
              <path stroke="currentColor" stroke-width="2" stroke-linecap="round" fill="none" d="M3.4,11.9l8.8,4.4l8.4-4.4"></path>
              <path stroke="currentColor" stroke-width="2" stroke-linecap="round" fill="none" d="M3.4,16.2l8.8,4.5l8.4-4.5"></path>
              <path stroke="currentColor" stroke-width="2" stroke-linecap="round" fill="none" d="M3.7,7.8l8.6-4.5l8,4.5l-8,4.3L3.7,7.8z"></path>
            </svg>
          ''',
        );
}

