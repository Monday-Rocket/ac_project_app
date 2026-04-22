import 'package:ac_project_app/cubits/links/edit_state.dart';
import 'package:ac_project_app/cubits/links/local_detail_edit_cubit.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([LocalLinkRepository])
import 'local_detail_edit_cubit_test.mocks.dart';

void main() {
  late MockLocalLinkRepository mockRepository;

  const testLink = Link(
    id: 1,
    url: 'https://test.com',
    title: 'Test',
    describe: 'desc',
    folderId: 1,
    time: '2024-01-01',
  );

  const testLocalLink = LocalLink(
    id: 1,
    folderId: 1,
    url: 'https://test.com',
    title: 'Test',
    describe: 'old desc',
    createdAt: '2024-01-01',
    updatedAt: '2024-01-01',
  );

  setUp(() {
    mockRepository = MockLocalLinkRepository();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<LocalLinkRepository>()) {
      getIt.unregister<LocalLinkRepository>();
    }
    getIt.registerSingleton<LocalLinkRepository>(mockRepository);
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<LocalLinkRepository>()) {
      getIt.unregister<LocalLinkRepository>();
    }
  });

  group('LocalDetailEditCubit', () {
    group('constructor', () {
      test('initial state is EditState(view)', () {
        final cubit = LocalDetailEditCubit(null);

        expect(cubit.state.type, EditStateType.view);
        expect(cubit.state.link, isNull);

        cubit.close();
      });

      test('constructor with link argument sets textController.text', () {
        final cubit = LocalDetailEditCubit({'link': testLink});

        expect(cubit.textController.text, 'desc');

        cubit.close();
      });

      test('constructor with null argument leaves textController empty', () {
        final cubit = LocalDetailEditCubit(null);

        expect(cubit.textController.text, '');

        cubit.close();
      });

      test('constructor with Map missing link key leaves textController empty',
          () {
        final cubit = LocalDetailEditCubit(<String, dynamic>{});

        // argument['link'] ?? const Link() -> Link() with null describe -> ''
        expect(cubit.textController.text, '');

        cubit.close();
      });
    });

    group('toggle()', () {
      test('toggle from view emits edit state', () {
        final cubit = LocalDetailEditCubit(null);
        expect(cubit.state.type, EditStateType.view);

        cubit.toggle();

        expect(cubit.state.type, EditStateType.edit);

        cubit.close();
      });

      test('toggle from edit emits view state', () {
        final cubit = LocalDetailEditCubit(null);
        cubit.toggle(); // view -> edit
        expect(cubit.state.type, EditStateType.edit);

        cubit.toggle(); // edit -> view

        expect(cubit.state.type, EditStateType.view);

        cubit.close();
      });

      test('toggle preserves existing link in state', () {
        final cubit = LocalDetailEditCubit(null);
        cubit.toggleEdit(testLink); // editedView with link
        cubit.toggle(); // editedView -> view (non-view branch)

        expect(cubit.state.type, EditStateType.view);

        cubit.close();
      });
    });

    group('toggleEdit()', () {
      test('toggleEdit sets editedView state with link', () {
        final cubit = LocalDetailEditCubit(null);

        cubit.toggleEdit(testLink);

        expect(cubit.state.type, EditStateType.editedView);
        expect(cubit.state.link, testLink);

        cubit.close();
      });
    });

    group('saveComment()', () {
      test('saveComment returns updated link with new describe', () async {
        when(mockRepository.getLinkById(1))
            .thenAnswer((_) async => testLocalLink);
        when(mockRepository.updateLink(any)).thenAnswer((_) async => 1);

        final cubit = LocalDetailEditCubit(null);
        cubit.textController.text = 'new comment';

        final result = await cubit.saveComment(testLink);

        expect(result.describe, 'new comment');
        expect(result.id, testLink.id);
        expect(result.url, testLink.url);

        verify(mockRepository.getLinkById(1)).called(1);
        verify(mockRepository.updateLink(any)).called(1);

        cubit.close();
      });

      test('saveComment with null link.id returns original link', () async {
        const linkWithNullId = Link(
          url: 'https://test.com',
          title: 'Test',
          describe: 'desc',
        );

        final cubit = LocalDetailEditCubit(null);
        cubit.textController.text = 'new comment';

        final result = await cubit.saveComment(linkWithNullId);

        expect(result, linkWithNullId);
        verifyNever(mockRepository.getLinkById(any));
        verifyNever(mockRepository.updateLink(any));

        cubit.close();
      });

      test('saveComment when getLinkById returns null returns original link',
          () async {
        when(mockRepository.getLinkById(1)).thenAnswer((_) async => null);

        final cubit = LocalDetailEditCubit(null);
        cubit.textController.text = 'new comment';

        final result = await cubit.saveComment(testLink);

        expect(result, testLink);
        verify(mockRepository.getLinkById(1)).called(1);
        verifyNever(mockRepository.updateLink(any));

        cubit.close();
      });

      test('saveComment when repo throws returns original link', () async {
        when(mockRepository.getLinkById(1))
            .thenThrow(Exception('DB error'));

        final cubit = LocalDetailEditCubit(null);
        cubit.textController.text = 'new comment';

        final result = await cubit.saveComment(testLink);

        expect(result, testLink);

        cubit.close();
      });
    });

    group('deleteLink()', () {
      test('deleteLink success returns true', () async {
        when(mockRepository.deleteLink(1)).thenAnswer((_) async => 1);

        final cubit = LocalDetailEditCubit(null);

        final result = await cubit.deleteLink(1);

        expect(result, isTrue);
        verify(mockRepository.deleteLink(1)).called(1);

        cubit.close();
      });

      test('deleteLink failure returns false', () async {
        when(mockRepository.deleteLink(1))
            .thenThrow(Exception('DB error'));

        final cubit = LocalDetailEditCubit(null);

        final result = await cubit.deleteLink(1);

        expect(result, isFalse);

        cubit.close();
      });
    });

    group('moveLink()', () {
      test('moveLink success returns true', () async {
        when(mockRepository.moveLink(1, 2)).thenAnswer((_) async => 1);

        final cubit = LocalDetailEditCubit(null);

        final result = await cubit.moveLink(1, 2);

        expect(result, isTrue);
        verify(mockRepository.moveLink(1, 2)).called(1);

        cubit.close();
      });

      test('moveLink failure returns false', () async {
        when(mockRepository.moveLink(1, 2))
            .thenThrow(Exception('DB error'));

        final cubit = LocalDetailEditCubit(null);

        final result = await cubit.moveLink(1, 2);

        expect(result, isFalse);

        cubit.close();
      });
    });

    group('backfillImageIfMissing()', () {
      const linkWithImage = Link(
        id: 1,
        url: 'https://test.com',
        image: 'https://test.com/existing.png',
        title: 'Test',
        folderId: 1,
      );

      const linkWithoutImage = Link(
        id: 2,
        url: 'https://test.com',
        title: 'Test',
        folderId: 1,
      );

      const localLinkWithoutImage = LocalLink(
        id: 2,
        folderId: 1,
        url: 'https://test.com',
        title: 'Test',
        createdAt: '2024-01-01',
        updatedAt: '2024-01-01',
      );

      test('link.image 이미 있으면 network 호출도 DB update 도 없음', () async {
        var metadataCalls = 0;
        final cubit = LocalDetailEditCubit(
          null,
          metadataLoader: (url) async {
            metadataCalls++;
            return Metadata()..image = 'https://test.com/og.png';
          },
        );

        await cubit.backfillImageIfMissing(linkWithImage);

        expect(metadataCalls, 0);
        verifyNever(mockRepository.getLinkById(any));
        verifyNever(mockRepository.updateLink(any));

        cubit.close();
      });

      test('image 없고 metadata.image 성공 → updateLink 호출 + editedView emit',
          () async {
        when(mockRepository.getLinkById(2))
            .thenAnswer((_) async => localLinkWithoutImage);
        when(mockRepository.updateLink(any)).thenAnswer((_) async => 1);

        final cubit = LocalDetailEditCubit(
          null,
          metadataLoader: (url) async {
            expect(url, 'https://test.com');
            return Metadata()..image = 'https://test.com/og.png';
          },
        );

        await cubit.backfillImageIfMissing(linkWithoutImage);

        final captured =
            verify(mockRepository.updateLink(captureAny)).captured;
        expect(captured, hasLength(1));
        expect((captured.first as LocalLink).image, 'https://test.com/og.png');

        expect(cubit.state.type, EditStateType.editedView);
        expect(cubit.state.link?.image, 'https://test.com/og.png');

        cubit.close();
      });

      test('metadata 로드 실패 → no-op', () async {
        final cubit = LocalDetailEditCubit(
          null,
          metadataLoader: (url) async => throw Exception('network fail'),
        );

        await cubit.backfillImageIfMissing(linkWithoutImage);

        verifyNever(mockRepository.getLinkById(any));
        verifyNever(mockRepository.updateLink(any));
        expect(cubit.state.type, EditStateType.view);
        expect(cubit.state.link, isNull);

        cubit.close();
      });

      test('metadata 는 성공했지만 image 가 null → no-op', () async {
        final cubit = LocalDetailEditCubit(
          null,
          metadataLoader: (url) async => Metadata(),
        );

        await cubit.backfillImageIfMissing(linkWithoutImage);

        verifyNever(mockRepository.getLinkById(any));
        verifyNever(mockRepository.updateLink(any));
        expect(cubit.state.type, EditStateType.view);

        cubit.close();
      });

      test('link.id 가 null 이면 no-op', () async {
        var metadataCalls = 0;
        const noIdLink = Link(url: 'https://test.com');
        final cubit = LocalDetailEditCubit(
          null,
          metadataLoader: (url) async {
            metadataCalls++;
            return Metadata()..image = 'https://test.com/og.png';
          },
        );

        await cubit.backfillImageIfMissing(noIdLink);

        expect(metadataCalls, 0);
        verifyNever(mockRepository.updateLink(any));

        cubit.close();
      });

      test('link.url 이 null 이면 no-op', () async {
        var metadataCalls = 0;
        const noUrlLink = Link(id: 3, folderId: 1);
        final cubit = LocalDetailEditCubit(
          null,
          metadataLoader: (url) async {
            metadataCalls++;
            return Metadata()..image = 'https://test.com/og.png';
          },
        );

        await cubit.backfillImageIfMissing(noUrlLink);

        expect(metadataCalls, 0);
        verifyNever(mockRepository.updateLink(any));

        cubit.close();
      });

      test('getLinkById 가 null 반환 → updateLink 호출 안 함', () async {
        when(mockRepository.getLinkById(2)).thenAnswer((_) async => null);

        final cubit = LocalDetailEditCubit(
          null,
          metadataLoader: (url) async =>
              Metadata()..image = 'https://test.com/og.png',
        );

        await cubit.backfillImageIfMissing(linkWithoutImage);

        verify(mockRepository.getLinkById(2)).called(1);
        verifyNever(mockRepository.updateLink(any));

        cubit.close();
      });
    });
  });
}
