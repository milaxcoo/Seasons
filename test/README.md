# Seasons App - Test Suite

This directory contains comprehensive tests for the Seasons Flutter application. The tests cover all major components including BLoCs, models, widgets, and integration tests.

## Test Structure

```
test/
├── mocks.dart                           # Shared mock classes
├── data/
│   ├── models/
│   │   ├── models_test.dart             # Tests for Nominee, Subject, Question models
│   │   ├── vote_result_test.dart        # Tests for VoteResult models
│   │   └── voting_event_test.dart       # Tests for VotingEvent model
│   └── repositories/
│       └── voting_repository_test.dart  # Repository interface tests
├── presentation/
│   ├── bloc/
│   │   ├── auth_bloc_test.dart          # Authentication BLoC tests
│   │   └── voting_bloc_test.dart        # Voting BLoC tests
│   └── screens/
│       ├── home_screen_test.dart        # HomeScreen widget tests
│       ├── login_screen_test.dart       # LoginScreen widget tests
│       └── voting_details_screen_test.dart # VotingDetailsScreen widget tests
└── integration/
    └── integration_test.dart            # End-to-end integration tests
```

## Test Coverage

### 1. Model Tests (`data/models/`)
- **models_test.dart**: Tests JSON parsing and equality for Nominee, Subject, and Question models
- **vote_result_test.dart**: Tests SubjectResult and QuestionResult models
- **voting_event_test.dart**: Comprehensive tests for VotingEvent model including:
  - JSON parsing for different event statuses (registration, active, completed)
  - Date parsing and timezone handling
  - Questions and results parsing
  - Error handling for malformed data

### 2. BLoC Tests (`presentation/bloc/`)

#### AuthBloc Tests
- Initial state verification
- **AppStarted event**: 
  - Token found with valid userLogin
  - Token not found
  - Token found but userLogin is null
- **LoggedIn event**:
  - Successful login
  - Failed login with invalid credentials
  - Login succeeds but userLogin is null
- **LoggedOut event**: Logout functionality
- State transitions (multiple logins, login followed by logout)

#### VotingBloc Tests
- Initial state verification
- **FetchEventsByStatus event**:
  - Successful fetch for all statuses
  - Empty list handling
  - Error handling
- **RegisterForEvent event**:
  - Successful registration
  - Already registered error
  - Event full error
- **SubmitVote event**:
  - Successful vote submission
  - Already voted error
  - Network error handling
  - Empty answers handling
- **FetchResults event**:
  - Successful results fetch
  - Empty results
  - Error handling
- State transitions and concurrent operations

### 3. Widget Tests (`presentation/screens/`)

#### LoginScreen Tests
- Main UI components rendering
- Info dialog display on login button tap
- Login event triggering on Continue button
- Dialog cancellation
- Navigation to HomeScreen on successful authentication
- Different auth state handling (Loading, Unauthenticated, Failure)

#### HomeScreen Tests
- Main layout components (header, footer, icons)
- Loading indicator during data fetch
- Event list rendering
- Empty state display
- Error message display
- Logout functionality
- Registration and voting status display
- Panel selector switching between event statuses
- Date information formatting

#### VotingDetailsScreen Tests
- Event details rendering
- Questions and answers display
- Submit button enabling/disabling based on selection
- Confirmation dialog display
- Vote submission
- Success dialog on successful vote
- Error snackbar on failure
- Already voted state handling
- Validation for incomplete answers
- Empty questions state

### 4. Repository Tests (`data/repositories/`)
- Authentication operations (login, logout, token management)
- Event fetching by status
- Event details retrieval
- Registration operations with error scenarios
- Vote submission with various error cases
- Results fetching

### 5. Integration Tests (`integration/`)
- Complete user flow: login → fetch events → logout
- Complete voting flow: register → fetch event → submit vote
- Error handling across multiple BLoCs
- Concurrent operations handling
- State persistence across different operations

## Running Tests

### Run all tests:
```bash
flutter test
```

### Run specific test file:
```bash
flutter test test/presentation/bloc/auth_bloc_test.dart
```

### Run tests with coverage:
```bash
flutter test --coverage
```

### Run integration tests:
```bash
flutter test test/integration/integration_test.dart
```

## Test Dependencies

The test suite uses the following packages:
- `flutter_test`: Flutter's testing framework
- `bloc_test`: Testing utilities for BLoC pattern
- `mocktail`: Modern mocking library for Dart
- `intl`: Internationalization for date formatting tests

## Mock Classes

All mock classes are centralized in `test/mocks.dart`:
- `MockVotingRepository`: Mock implementation of VotingRepository
- `MockDraftService`: Mock implementation of DraftService
- `MockAuthBloc`: Mock for AuthBloc
- `MockVotingBloc`: Mock for VotingBloc

## Best Practices Followed

1. **Arrange-Act-Assert Pattern**: All tests follow the AAA pattern for clarity
2. **Descriptive Test Names**: Test names clearly describe what is being tested
3. **Isolated Tests**: Each test is independent and can run in isolation
4. **Proper Setup/Teardown**: Resources are properly initialized and cleaned up
5. **Mock Verification**: Verify that expected interactions with mocks occurred
6. **Edge Cases**: Tests cover both happy paths and error scenarios
7. **Widget Testing**: Uses `pumpAndSettle()` for proper async widget rendering
8. **BLoC Testing**: Uses `blocTest` for clean BLoC testing with proper state verification

## Common Testing Patterns

### Testing BLoCs:
```dart
blocTest<AuthBloc, AuthState>(
  'description of what is being tested',
  build: () {
    // Setup mocks
    when(() => mockRepository.login('user', 'pass'))
        .thenAnswer((_) async => 'token');
    return authBloc;
  },
  act: (bloc) => bloc.add(LoggedIn(login: 'user', password: 'pass')),
  expect: () => [
    AuthLoading(),
    AuthAuthenticated(userLogin: 'user'),
  ],
  verify: (_) {
    // Verify mock interactions
    verify(() => mockRepository.login('user', 'pass')).called(1);
  },
);
```

### Testing Widgets:
```dart
testWidgets('description', (tester) async {
  // Arrange
  when(() => mockBloc.state).thenReturn(SomeState());
  
  // Act
  await tester.pumpWidget(createTestWidget());
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.text('Expected Text'), findsOneWidget);
});
```

### Testing Models:
```dart
test('fromJson parses correctly', () {
  // Arrange
  final json = {'id': '1', 'name': 'Test'};
  
  // Act
  final model = Model.fromJson(json);
  
  // Assert
  expect(model.id, '1');
  expect(model.name, 'Test');
});
```

## Continuous Integration

These tests are designed to run in CI/CD pipelines. Ensure that:
1. All tests pass before merging code
2. Test coverage remains above the threshold
3. New features include corresponding tests
4. Failing tests are investigated and fixed immediately

## Contributing

When adding new features:
1. Write tests first (TDD approach recommended)
2. Ensure all existing tests still pass
3. Add tests for both success and failure scenarios
4. Update this README if new test categories are added

## Troubleshooting

### Tests fail with "No provider found"
- Ensure all required BLoC providers are included in test widget tree
- Check that `RepositoryProvider` is provided when needed

### Widget tests fail with "pump" errors
- Use `pumpAndSettle()` instead of `pump()` for async operations
- Add appropriate delays for animations

### BLoC tests emit unexpected states
- Verify mock setup is correct
- Check that `registerFallbackValue` is called for custom types
- Ensure `stream` is properly mocked for BLoC listeners

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [BLoC Testing Documentation](https://bloclibrary.dev/#/testing)
- [Mocktail Documentation](https://pub.dev/packages/mocktail)
