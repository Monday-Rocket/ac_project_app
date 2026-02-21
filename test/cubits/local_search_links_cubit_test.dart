import 'package:ac_project_app/cubits/home/local_search_links_cubit.dart';
import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([LocalLinkRepository])
import 'local_search_links_cubit_test.mocks.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

LocalLink _makeLink(int id, {String url = 'https://test.com', String title = 'Test'}) =>
    LocalLink(
      id: id,
      folderId: 1,
      url: url,
      title: title,
      createdAt: '2024-01-01',
      updatedAt: '2024-01-01',
    );

List<LocalLink> _makeLinks(int count) =>
    List.generate(count, (i) => _makeLink(i + 1, title: 'Link ${i + 1}'));

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  late MockLocalLinkRepository mockRepo;

  setUp(() {
    mockRepo = MockLocalLinkRepository();

    // Reset GetIt and register the mock
    if (getIt.isRegistered<LocalLinkRepository>()) {
      getIt.unregister<LocalLinkRepository>();
    }
    getIt.registerSingleton<LocalLinkRepository>(mockRepo);
  });

  tearDown(() {
    if (getIt.isRegistered<LocalLinkRepository>()) {
      getIt.unregister<LocalLinkRepository>();
    }
  });

  // -------------------------------------------------------------------------
  // 1. Initial state
  // -------------------------------------------------------------------------
  group('initial state', () {
    test('is LinkListInitialState', () {
      final cubit = LocalSearchLinksCubit();
      expect(cubit.state, isA<LinkListInitialState>());
      cubit.close();
    });

    test('hasMore starts as ScrollableType.cannot', () {
      final cubit = LocalSearchLinksCubit();
      expect(cubit.hasMore.state, ScrollableType.cannot);
      cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // 2. searchMyLinks – basic success
  // -------------------------------------------------------------------------
  group('searchMyLinks', () {
    blocTest<LocalSearchLinksCubit, LinkListState>(
      'emits [loading, loaded] with correct links on success',
      build: () {
        when(mockRepo.searchLinks(any))
            .thenAnswer((_) async => _makeLinks(3));
        return LocalSearchLinksCubit();
      },
      act: (cubit) => cubit.searchMyLinks('flutter', 0),
      expect: () => [
        isA<LinkListLoadingState>(),
        isA<LinkListLoadedState>(),
      ],
      verify: (cubit) {
        final state = cubit.state as LinkListLoadedState;
        expect(state.links.length, 3);
        expect(state.totalCount, 3);
      },
    );

    // -----------------------------------------------------------------------
    // 3. searchMyLinks – empty results
    // -----------------------------------------------------------------------
    blocTest<LocalSearchLinksCubit, LinkListState>(
      'emits [loading, loaded] with empty list when no results',
      build: () {
        when(mockRepo.searchLinks(any)).thenAnswer((_) async => []);
        return LocalSearchLinksCubit();
      },
      act: (cubit) => cubit.searchMyLinks('zzznomatch', 0),
      expect: () => [
        isA<LinkListLoadingState>(),
        isA<LinkListLoadedState>(),
      ],
      verify: (cubit) {
        final state = cubit.state as LinkListLoadedState;
        expect(state.links, isEmpty);
        expect(state.totalCount, 0);
      },
    );

    // -----------------------------------------------------------------------
    // 4. searchMyLinks – pagination (page 0 then page 1)
    // -----------------------------------------------------------------------
    blocTest<LocalSearchLinksCubit, LinkListState>(
      'paginates correctly: page 0 returns first 20, page 1 returns next batch',
      build: () {
        // 25 results total
        when(mockRepo.searchLinks(any))
            .thenAnswer((_) async => _makeLinks(25));
        return LocalSearchLinksCubit();
      },
      act: (cubit) async {
        await cubit.searchMyLinks('test', 0);
        await cubit.searchMyLinks('test', 1);
      },
      verify: (cubit) {
        final state = cubit.state as LinkListLoadedState;
        // page 1 contains the remaining 5
        expect(state.links.length, 5);
        expect(state.totalCount, 25);
        // totalLinks accumulates both pages
        expect(cubit.totalLinks.length, 25);
      },
    );

    // -----------------------------------------------------------------------
    // 5. searchMyLinks – hasMore is `can` when results > 20
    // -----------------------------------------------------------------------
    blocTest<LocalSearchLinksCubit, LinkListState>(
      'sets hasMore to ScrollableType.can when total results exceed page size',
      build: () {
        when(mockRepo.searchLinks(any))
            .thenAnswer((_) async => _makeLinks(21));
        return LocalSearchLinksCubit();
      },
      act: (cubit) => cubit.searchMyLinks('test', 0),
      verify: (cubit) {
        expect(cubit.hasMore.state, ScrollableType.can);
      },
    );

    // -----------------------------------------------------------------------
    // 6. searchMyLinks – hasMore is `cannot` when results <= 20
    // -----------------------------------------------------------------------
    blocTest<LocalSearchLinksCubit, LinkListState>(
      'sets hasMore to ScrollableType.cannot when total results fit in one page',
      build: () {
        when(mockRepo.searchLinks(any))
            .thenAnswer((_) async => _makeLinks(20));
        return LocalSearchLinksCubit();
      },
      act: (cubit) => cubit.searchMyLinks('test', 0),
      verify: (cubit) {
        expect(cubit.hasMore.state, ScrollableType.cannot);
      },
    );

    // -----------------------------------------------------------------------
    // 7. page 0 clears totalLinks from previous search
    // -----------------------------------------------------------------------
    blocTest<LocalSearchLinksCubit, LinkListState>(
      'page 0 clears previous totalLinks before accumulating new results',
      build: () {
        when(mockRepo.searchLinks(any))
            .thenAnswer((_) async => _makeLinks(3));
        return LocalSearchLinksCubit();
      },
      act: (cubit) async {
        await cubit.searchMyLinks('first', 0);
        await cubit.searchMyLinks('second', 0); // new search resets
      },
      verify: (cubit) {
        // Only the second search's 3 links should be in totalLinks
        expect(cubit.totalLinks.length, 3);
      },
    );

    // -----------------------------------------------------------------------
    // 12. error handling
    // -----------------------------------------------------------------------
    blocTest<LocalSearchLinksCubit, LinkListState>(
      'emits [loading, error] when repository throws',
      build: () {
        when(mockRepo.searchLinks(any))
            .thenThrow(Exception('DB failure'));
        return LocalSearchLinksCubit();
      },
      act: (cubit) => cubit.searchMyLinks('test', 0),
      expect: () => [
        isA<LinkListLoadingState>(),
        isA<LinkListErrorState>(),
      ],
      verify: (cubit) {
        final state = cubit.state as LinkListErrorState;
        expect(state.message, contains('DB failure'));
      },
    );
  });

  // -------------------------------------------------------------------------
  // 7 (public). searchLinks delegates to searchMyLinks
  // -------------------------------------------------------------------------
  group('searchLinks', () {
    blocTest<LocalSearchLinksCubit, LinkListState>(
      'delegates to searchMyLinks and produces same states',
      build: () {
        when(mockRepo.searchLinks(any))
            .thenAnswer((_) async => _makeLinks(5));
        return LocalSearchLinksCubit();
      },
      act: (cubit) => cubit.searchLinks('flutter', 0),
      expect: () => [
        isA<LinkListLoadingState>(),
        isA<LinkListLoadedState>(),
      ],
      verify: (cubit) {
        final state = cubit.state as LinkListLoadedState;
        expect(state.links.length, 5);
        expect(state.totalCount, 5);
        // currentText and page are set correctly
        expect(cubit.currentText, 'flutter');
        expect(cubit.page, 0);
      },
    );
  });

  // -------------------------------------------------------------------------
  // 8. refresh
  // -------------------------------------------------------------------------
  group('refresh', () {
    blocTest<LocalSearchLinksCubit, LinkListState>(
      'clears state and re-searches with currentText from page 0',
      build: () {
        when(mockRepo.searchLinks(any))
            .thenAnswer((_) async => _makeLinks(3));
        return LocalSearchLinksCubit();
      },
      act: (cubit) async {
        await cubit.searchMyLinks('flutter', 0);
        cubit.refresh();
        // Wait for the async refresh to complete
        await Future.delayed(Duration.zero);
      },
      verify: (cubit) {
        expect(cubit.state, isA<LinkListLoadedState>());
        expect(cubit.page, 0);
        // Repository was called twice: initial search + refresh
        verify(mockRepo.searchLinks('flutter')).called(2);
      },
    );
  });

  // -------------------------------------------------------------------------
  // 9. loadMore – loads next page when hasMore is can
  // -------------------------------------------------------------------------
  group('loadMore', () {
    blocTest<LocalSearchLinksCubit, LinkListState>(
      'calls searchMyLinks with page+1 when hasMore is can',
      build: () {
        when(mockRepo.searchLinks(any))
            .thenAnswer((_) async => _makeLinks(25));
        return LocalSearchLinksCubit();
      },
      act: (cubit) async {
        await cubit.searchMyLinks('test', 0);
        // After page 0, hasMore == can (25 > 20)
        cubit.loadMore();
        await Future.delayed(Duration.zero);
      },
      verify: (cubit) {
        expect(cubit.page, 1);
        expect(cubit.state, isA<LinkListLoadedState>());
        final state = cubit.state as LinkListLoadedState;
        // Page 1 contains remaining 5 links
        expect(state.links.length, 5);
      },
    );

    // -----------------------------------------------------------------------
    // 10. loadMore does nothing when hasMore is cannot
    // -----------------------------------------------------------------------
    blocTest<LocalSearchLinksCubit, LinkListState>(
      'does nothing when hasMore is ScrollableType.cannot',
      build: () {
        when(mockRepo.searchLinks(any))
            .thenAnswer((_) async => _makeLinks(5));
        return LocalSearchLinksCubit();
      },
      act: (cubit) async {
        await cubit.searchMyLinks('test', 0);
        // hasMore == cannot (5 <= 20)
        cubit.loadMore();
        await Future.delayed(Duration.zero);
      },
      verify: (cubit) {
        // Page should remain 0, no extra calls
        expect(cubit.page, 0);
        // Repository called exactly once
        verify(mockRepo.searchLinks('test')).called(1);
      },
    );
  });

  // -------------------------------------------------------------------------
  // 11. clear resets state
  // -------------------------------------------------------------------------
  group('clear', () {
    test('resets totalLinks, allSearchResults, and currentText', () async {
      when(mockRepo.searchLinks(any)).thenAnswer((_) async => _makeLinks(5));

      final cubit = LocalSearchLinksCubit();
      await cubit.searchMyLinks('flutter', 0);

      // Verify pre-clear state
      expect(cubit.totalLinks, isNotEmpty);
      expect(cubit.currentText, 'flutter');

      cubit.clear();

      expect(cubit.totalLinks, isEmpty);
      expect(cubit.currentText, '');
      // State is not reset by clear() – it stays as last emitted state
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // loadedNewLinks
  // -------------------------------------------------------------------------
  group('loadedNewLinks', () {
    test('sets hasAdded to false', () async {
      when(mockRepo.searchLinks(any)).thenAnswer((_) async => _makeLinks(3));

      final cubit = LocalSearchLinksCubit();
      await cubit.searchMyLinks('test', 0);

      // After search, hasAdded should be true
      expect(cubit.hasAdded, isTrue);

      cubit.loadedNewLinks();
      expect(cubit.hasAdded, isFalse);

      await cubit.close();
    });
  });
}
