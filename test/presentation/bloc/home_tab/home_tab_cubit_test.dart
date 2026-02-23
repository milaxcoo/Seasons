import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/bloc/home_tab/home_tab_cubit.dart';

void main() {
  group('HomeTabCubit', () {
    test('starts at index 0 by default', () {
      final cubit = HomeTabCubit();
      addTearDown(cubit.close);

      expect(cubit.state.index, 0);
      expect(cubit.state.source, 'init');
    });

    test('normalizes out-of-range initial index', () {
      final cubit = HomeTabCubit(initialIndex: 42);
      addTearDown(cubit.close);

      expect(cubit.state.index, 2);
    });

    test('updates index and source when changed', () {
      final cubit = HomeTabCubit();
      addTearDown(cubit.close);

      cubit.setIndex(1, source: 'user_tap');

      expect(cubit.state.index, 1);
      expect(cubit.state.source, 'user_tap');
    });

    test('does not emit when index is unchanged', () async {
      final cubit = HomeTabCubit();
      addTearDown(cubit.close);

      final emittedStates = <HomeTabState>[];
      final subscription = cubit.stream.listen(emittedStates.add);
      addTearDown(subscription.cancel);

      cubit.setIndex(0, source: 'noop');

      await Future<void>.delayed(Duration.zero);
      expect(emittedStates, isEmpty);
    });
  });
}
