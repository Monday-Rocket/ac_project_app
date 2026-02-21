import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/local_folders_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([LocalFolderRepository])
import 'local_folders_cubit_test.mocks.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

LocalFolder makeLocalFolder({
  int id = 1,
  String name = 'Test Folder',
  bool isClassified = true,
  int linksCount = 0,
}) =>
    LocalFolder(
      id: id,
      name: name,
      isClassified: isClassified,
      createdAt: '2024-01-01',
      updatedAt: '2024-01-01',
      linksCount: linksCount,
    );

Folder makeFolder({
  int? id = 1,
  String name = 'Test Folder',
  bool visible = true,
  int links = 0,
}) =>
    Folder(
      id: id,
      name: name,
      visible: visible,
      links: links,
      isClassified: visible,
    );

/// Register a fresh mock in getIt and return it.
MockLocalFolderRepository _registerMock() {
  final mock = MockLocalFolderRepository();
  getIt.registerSingleton<LocalFolderRepository>(mock);
  return mock;
}

/// Stub [getAllFolders] so the cubit constructor call succeeds.
void _stubGetAll(MockLocalFolderRepository mock, List<LocalFolder> folders) {
  when(mock.getAllFolders()).thenAnswer((_) async => folders);
}

/// Build a cubit and yield to the event loop so the constructor's async work
/// completes before the caller proceeds.
Future<LocalFoldersCubit> _buildAndDrain({
  bool excludeUnclassified = false,
}) async {
  final cubit = LocalFoldersCubit(
    excludeUnclassified: excludeUnclassified ? true : null,
  );
  await Future<void>.delayed(Duration.zero);
  return cubit;
}

/// Collect all states emitted while [action] runs.
/// Subscribes BEFORE calling action, then awaits action and an extra microtask
/// so that async-emitted states are captured before we cancel.
Future<List<FoldersState>> collectStates(
  LocalFoldersCubit cubit,
  Future<void> Function() action,
) async {
  final emitted = <FoldersState>[];
  final sub = cubit.stream.listen(emitted.add);
  await action();
  // One extra microtask ensures states emitted inside the action's async gaps
  // have been delivered to the listener.
  await Future<void>.delayed(Duration.zero);
  await sub.cancel();
  return emitted;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  late MockLocalFolderRepository mockRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    mockRepo = _registerMock();
    _stubGetAll(mockRepo, []);
  });

  tearDown(() async {
    await getIt.reset();
  });

  // -------------------------------------------------------------------------
  // Constructor — default behaviour
  // -------------------------------------------------------------------------

  group('constructor — default (excludeUnclassified: false)', () {
    test('eventually emits FolderLoadedState after build', () async {
      _stubGetAll(mockRepo, [makeLocalFolder(linksCount: 3)]);
      final cubit = await _buildAndDrain();

      expect(cubit.state, isA<FolderLoadedState>());
      await cubit.close();
    });

    test('FolderLoadedState has correct totalLinksText', () async {
      _stubGetAll(mockRepo, [
        makeLocalFolder(id: 1, name: 'A', linksCount: 4),
        makeLocalFolder(id: 2, name: 'B', linksCount: 6),
      ]);
      final cubit = await _buildAndDrain();

      final state = cubit.state as FolderLoadedState;
      expect(state.totalLinksText, '10');
      await cubit.close();
    });

    test('calls getAllFolders (not getClassifiedFolders) by default', () async {
      final cubit = await _buildAndDrain();

      verify(mockRepo.getAllFolders()).called(1);
      verifyNever(mockRepo.getClassifiedFolders());
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // Constructor — excludeUnclassified: true
  // -------------------------------------------------------------------------

  group('constructor — excludeUnclassified: true', () {
    test('calls getClassifiedFolders instead of getAllFolders', () async {
      when(mockRepo.getClassifiedFolders())
          .thenAnswer((_) async => [makeLocalFolder()]);

      final cubit = await _buildAndDrain(excludeUnclassified: true);

      verify(mockRepo.getClassifiedFolders()).called(1);
      verifyNever(mockRepo.getAllFolders());
      expect(cubit.state, isA<FolderLoadedState>());
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // getFolders()
  // -------------------------------------------------------------------------

  group('getFolders()', () {
    test('emits [loading, loaded] with distinct folder data', () async {
      // First load: empty list (from constructor).
      _stubGetAll(mockRepo, []);
      final cubit = await _buildAndDrain();

      // Second load: different folder list so Equatable won't deduplicate.
      _stubGetAll(mockRepo, [makeLocalFolder(id: 99, name: 'New')]);
      final emitted = await collectStates(cubit, () => cubit.getFolders());

      expect(emitted, [isA<FolderLoadingState>(), isA<FolderLoadedState>()]);
      final loaded = emitted[1] as FolderLoadedState;
      expect(loaded.folders.first.name, 'New');
      await cubit.close();
    });

    test('saves totalLinksCount to SharedPreferences when isFirst: true',
        () async {
      _stubGetAll(mockRepo, [makeLocalFolder(linksCount: 7)]);
      final cubit = await _buildAndDrain();

      // Constructor already saved 7. Now change to 9 and call with isFirst.
      _stubGetAll(mockRepo, [makeLocalFolder(id: 2, linksCount: 9)]);
      await collectStates(cubit, () => cubit.getFolders(isFirst: true));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('savedLinksCount'), 9);
      await cubit.close();
    });

    test('emits [loading, error] when repository throws', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.getAllFolders()).thenThrow(Exception('DB error'));
      final emitted = await collectStates(cubit, () => cubit.getFolders());

      expect(emitted, [isA<FolderLoadingState>(), isA<FolderErrorState>()]);
      await cubit.close();
    });

    test('emits [loading, loaded] even when called multiple times in sequence',
        () async {
      // First load: id=1 list.
      _stubGetAll(mockRepo, [makeLocalFolder(id: 1, name: 'First')]);
      final cubit = await _buildAndDrain();

      // Second load: id=2 list — distinct from the first, so no deduplication.
      _stubGetAll(mockRepo, [makeLocalFolder(id: 2, name: 'Second')]);
      final emitted = await collectStates(cubit, () => cubit.getFolders());

      expect(emitted, [isA<FolderLoadingState>(), isA<FolderLoadedState>()]);
      final loaded = emitted[1] as FolderLoadedState;
      expect(loaded.folders.first.name, 'Second');
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // getFoldersWithoutUnclassified()
  // -------------------------------------------------------------------------

  group('getFoldersWithoutUnclassified()', () {
    test('emits [loading, loaded] using getClassifiedFolders', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.getClassifiedFolders())
          .thenAnswer((_) async => [makeLocalFolder(id: 5, name: 'Classified')]);

      final emitted = await collectStates(
        cubit,
        () => cubit.getFoldersWithoutUnclassified(),
      );

      expect(emitted, [isA<FolderLoadingState>(), isA<FolderLoadedState>()]);
      final loaded = emitted[1] as FolderLoadedState;
      expect(loaded.folders.first.name, 'Classified');
      await cubit.close();
    });

    test('emits [loading, error] when getClassifiedFolders throws', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.getClassifiedFolders()).thenThrow(Exception('fail'));
      final emitted = await collectStates(
        cubit,
        () => cubit.getFoldersWithoutUnclassified(),
      );

      expect(emitted, [isA<FolderLoadingState>(), isA<FolderErrorState>()]);
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // createFolder()
  // -------------------------------------------------------------------------

  group('createFolder()', () {
    test('returns created id as an integer', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.createFolder(any)).thenAnswer((_) async => 42);
      _stubGetAll(mockRepo, [makeLocalFolder(id: 42, name: 'New')]);

      final id = await cubit.createFolder('New');

      expect(id, 42);
      verify(mockRepo.createFolder(any)).called(1);
      await cubit.close();
    });

    test('emits [loading, loaded] after successful creation', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.createFolder(any)).thenAnswer((_) async => 5);
      // Return a distinct list so Equatable does not deduplicate.
      _stubGetAll(mockRepo, [makeLocalFolder(id: 5, name: 'Created')]);

      final emitted =
          await collectStates(cubit, () => cubit.createFolder('Created'));

      expect(emitted, [isA<FolderLoadingState>(), isA<FolderLoadedState>()]);
      await cubit.close();
    });

    test('returns null when repository throws', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.createFolder(any)).thenThrow(Exception('insert failed'));
      final id = await cubit.createFolder('Bad Folder');

      expect(id, isNull);
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // changeName()
  // -------------------------------------------------------------------------

  group('changeName()', () {
    test('returns true and calls updateFolder with the new name', () async {
      _stubGetAll(mockRepo, [makeLocalFolder()]);
      final cubit = await _buildAndDrain();

      final localFolder = makeLocalFolder(id: 1, name: 'Old Name');
      when(mockRepo.getFolderById(1)).thenAnswer((_) async => localFolder);
      when(mockRepo.updateFolder(any)).thenAnswer((_) async => 1);
      _stubGetAll(mockRepo, [makeLocalFolder(id: 1, name: 'New Name')]);

      final result = await cubit.changeName(makeFolder(id: 1), 'New Name');

      expect(result, isTrue);
      final captured =
          verify(mockRepo.updateFolder(captureAny)).captured.single
              as LocalFolder;
      expect(captured.name, 'New Name');
      await cubit.close();
    });

    test('returns false when folder id is null', () async {
      final cubit = await _buildAndDrain();

      final result = await cubit.changeName(makeFolder(id: null), 'Whatever');

      expect(result, isFalse);
      verifyNever(mockRepo.getFolderById(any));
      await cubit.close();
    });

    test('returns false when getFolderById returns null', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.getFolderById(99)).thenAnswer((_) async => null);

      final result = await cubit.changeName(makeFolder(id: 99), 'New');

      expect(result, isFalse);
      verifyNever(mockRepo.updateFolder(any));
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // delete()
  // -------------------------------------------------------------------------

  group('delete()', () {
    test('returns true and calls deleteFolder with the folder id', () async {
      _stubGetAll(mockRepo, [makeLocalFolder()]);
      final cubit = await _buildAndDrain();

      when(mockRepo.deleteFolder(1)).thenAnswer((_) async => 1);
      _stubGetAll(mockRepo, []);

      final result = await cubit.delete(makeFolder(id: 1));

      expect(result, isTrue);
      verify(mockRepo.deleteFolder(1)).called(1);
      await cubit.close();
    });

    test('returns false when folder id is null', () async {
      final cubit = await _buildAndDrain();

      final result = await cubit.delete(makeFolder(id: null));

      expect(result, isFalse);
      verifyNever(mockRepo.deleteFolder(any));
      await cubit.close();
    });

    test('returns false when deleteFolder throws', () async {
      _stubGetAll(mockRepo, [makeLocalFolder()]);
      final cubit = await _buildAndDrain();

      when(mockRepo.deleteFolder(1)).thenThrow(Exception('delete failed'));

      final result = await cubit.delete(makeFolder(id: 1));

      expect(result, isFalse);
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // filter()
  //
  // filter() calls emit() synchronously inside a Future<void>, which means the
  // new state is set on the cubit immediately. We read cubit.state directly
  // instead of relying on the stream (which deduplicates equal states via
  // Equatable).
  // -------------------------------------------------------------------------

  group('filter()', () {
    Future<LocalFoldersCubit> _buildWithTwoFolders() async {
      _stubGetAll(mockRepo, [
        makeLocalFolder(id: 1, name: 'Alpha', linksCount: 1),
        makeLocalFolder(id: 2, name: 'Beta', linksCount: 2),
      ]);
      return _buildAndDrain();
    }

    test('with empty string emits all folders', () async {
      final cubit = await _buildWithTwoFolders();

      await cubit.filter('');

      final state = cubit.state as FolderLoadedState;
      expect(state.folders.length, 2);
      await cubit.close();
    });

    test('with a matching query emits only matching folders', () async {
      final cubit = await _buildWithTwoFolders();

      await cubit.filter('Alp');

      final state = cubit.state as FolderLoadedState;
      expect(state.folders.map((f) => f.name).toList(), ['Alpha']);
      await cubit.close();
    });

    test('with a non-matching query emits an empty folder list', () async {
      final cubit = await _buildWithTwoFolders();

      await cubit.filter('ZZZ');

      final state = cubit.state as FolderLoadedState;
      expect(state.folders, isEmpty);
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // transferVisible()
  // -------------------------------------------------------------------------

  group('transferVisible()', () {
    test('toggles isClassified from true to false and returns true', () async {
      _stubGetAll(mockRepo, [makeLocalFolder()]);
      final cubit = await _buildAndDrain();

      final localFolder = makeLocalFolder(id: 1, isClassified: true);
      when(mockRepo.getFolderById(1)).thenAnswer((_) async => localFolder);
      when(mockRepo.updateFolder(any)).thenAnswer((_) async => 1);
      _stubGetAll(mockRepo, []);

      final result = await cubit.transferVisible(makeFolder(id: 1));

      expect(result, isTrue);
      final captured =
          verify(mockRepo.updateFolder(captureAny)).captured.single
              as LocalFolder;
      expect(captured.isClassified, isFalse);
      await cubit.close();
    });

    test('returns false when folder id is null', () async {
      final cubit = await _buildAndDrain();

      final result = await cubit.transferVisible(makeFolder(id: null));

      expect(result, isFalse);
      verifyNever(mockRepo.getFolderById(any));
      await cubit.close();
    });

    test('returns false when getFolderById returns null', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.getFolderById(1)).thenAnswer((_) async => null);

      final result = await cubit.transferVisible(makeFolder(id: 1));

      expect(result, isFalse);
      verifyNever(mockRepo.updateFolder(any));
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // changeNameAndVisible()
  // -------------------------------------------------------------------------

  group('changeNameAndVisible()', () {
    test('updates name and isClassified from Folder.visible', () async {
      _stubGetAll(mockRepo, [makeLocalFolder()]);
      final cubit = await _buildAndDrain();

      final localFolder =
          makeLocalFolder(id: 1, name: 'Old', isClassified: true);
      when(mockRepo.getFolderById(1)).thenAnswer((_) async => localFolder);
      when(mockRepo.updateFolder(any)).thenAnswer((_) async => 1);
      _stubGetAll(mockRepo, []);

      // visible: false → isClassified should become false in the updated record.
      final folder = makeFolder(id: 1, name: 'New Name', visible: false);
      final result = await cubit.changeNameAndVisible(folder);

      expect(result, isTrue);
      final captured =
          verify(mockRepo.updateFolder(captureAny)).captured.single
              as LocalFolder;
      expect(captured.name, 'New Name');
      expect(captured.isClassified, isFalse);
      await cubit.close();
    });

    test('returns false when folder id is null', () async {
      final cubit = await _buildAndDrain();

      final result = await cubit.changeNameAndVisible(makeFolder(id: null));

      expect(result, isFalse);
      verifyNever(mockRepo.getFolderById(any));
      await cubit.close();
    });

    test('returns false when getFolderById returns null', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.getFolderById(1)).thenAnswer((_) async => null);

      final result = await cubit.changeNameAndVisible(makeFolder(id: 1));

      expect(result, isFalse);
      verifyNever(mockRepo.updateFolder(any));
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // getUnclassifiedFolderId()
  // -------------------------------------------------------------------------

  group('getUnclassifiedFolderId()', () {
    test('returns the id from the unclassified folder', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.getUnclassifiedFolder()).thenAnswer(
        (_) async => makeLocalFolder(id: 7, isClassified: false),
      );

      final id = await cubit.getUnclassifiedFolderId();

      expect(id, 7);
      await cubit.close();
    });

    test('returns null when there is no unclassified folder', () async {
      final cubit = await _buildAndDrain();

      when(mockRepo.getUnclassifiedFolder()).thenAnswer((_) async => null);

      final id = await cubit.getUnclassifiedFolderId();

      expect(id, isNull);
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // getTotalLinksCount()
  // -------------------------------------------------------------------------

  group('getTotalLinksCount()', () {
    test('returns sum of all folder link counts', () async {
      _stubGetAll(mockRepo, [
        makeLocalFolder(id: 1, linksCount: 3),
        makeLocalFolder(id: 2, linksCount: 7),
        makeLocalFolder(id: 3, linksCount: 0),
      ]);
      final cubit = await _buildAndDrain();

      expect(cubit.getTotalLinksCount(), 10);
      await cubit.close();
    });

    test('returns 0 when the folder list is empty', () async {
      final cubit = await _buildAndDrain();

      expect(cubit.getTotalLinksCount(), 0);
      await cubit.close();
    });
  });

  // -------------------------------------------------------------------------
  // addedLinksCount inside FolderLoadedState
  // -------------------------------------------------------------------------

  group('addedLinksCount', () {
    test('is 0 when savedLinksCount matches current total', () async {
      SharedPreferences.setMockInitialValues({'savedLinksCount': 5});
      _stubGetAll(mockRepo, [makeLocalFolder(linksCount: 5)]);

      final cubit = await _buildAndDrain();
      final state = cubit.state as FolderLoadedState;

      expect(state.addedLinksCount, 0);
      await cubit.close();
    });

    test('is positive when new links were added since last save', () async {
      SharedPreferences.setMockInitialValues({'savedLinksCount': 3});
      _stubGetAll(mockRepo, [makeLocalFolder(linksCount: 8)]);

      final cubit = await _buildAndDrain();
      final state = cubit.state as FolderLoadedState;

      expect(state.addedLinksCount, 5); // 8 total − 3 saved
      await cubit.close();
    });
  });
}
