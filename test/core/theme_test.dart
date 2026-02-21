import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seasons/core/theme.dart';

void main() {
  testWidgets('AppTheme.lightTheme keeps key color and typography invariants',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final ThemeData theme = AppTheme.lightTheme;

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppTheme.primaryColor);
    expect(theme.colorScheme.secondary, AppTheme.secondaryColor);
    expect(theme.scaffoldBackgroundColor, AppTheme.backgroundColor);

    expect(theme.textTheme.bodyLarge, isNotNull);
    expect(theme.textTheme.titleLarge?.fontFamily, 'HemiHead');
    expect(theme.textTheme.headlineMedium?.fontStyle, FontStyle.italic);
  });
}
