import 'dart:async';

import 'package:ac_project_app/cubits/links/link_check_cubit.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([LocalLinkRepository])
import 'link_check_cubit_test.mocks.dart';

void main() {
  late MockLocalLinkRepository repo;

  setUp(() {
    repo = MockLocalLinkRepository();
  });

  group('LinkCheckCubit', () {
    test('초기 상태는 initial', () {
      when(repo.getAllLinks()).thenAnswer((_) async => const []);
      final cubit = LinkCheckCubit(linkRepository: repo, autoStart: false);
      expect(cubit.state.status, LinkCheckStatus.initial);
      cubit.close();
    });

    blocTest<LinkCheckCubit, LinkCheckState>(
      '링크 0건 → checking → empty 로 즉시 전환',
      build: () {
        when(repo.getAllLinks()).thenAnswer((_) async => const []);
        return LinkCheckCubit(linkRepository: repo, autoStart: false);
      },
      act: (cubit) => cubit.checkAllLinks(),
      expect: () => [
        predicate<LinkCheckState>(
          (s) => s.status == LinkCheckStatus.checking,
          'checking',
        ),
        predicate<LinkCheckState>(
          (s) => s.status == LinkCheckStatus.empty,
          'empty',
        ),
      ],
    );

    test('autoStart=true 이면 생성 즉시 검사 트리거', () async {
      when(repo.getAllLinks()).thenAnswer((_) async => const []);

      final cubit = LinkCheckCubit(linkRepository: repo);
      final emitted = <LinkCheckStatus>[];
      final sub = cubit.stream.listen((s) => emitted.add(s.status));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(repo.getAllLinks()).called(1);
      expect(emitted, contains(LinkCheckStatus.empty));

      await sub.cancel();
      await cubit.close();
    });

    blocTest<LinkCheckCubit, LinkCheckState>(
      'repository 예외 → error 상태',
      build: () {
        when(repo.getAllLinks()).thenThrow(Exception('db failed'));
        return LinkCheckCubit(linkRepository: repo, autoStart: false);
      },
      act: (cubit) => cubit.checkAllLinks(),
      expect: () => [
        predicate<LinkCheckState>(
          (s) => s.status == LinkCheckStatus.checking,
        ),
        predicate<LinkCheckState>(
          (s) =>
              s.status == LinkCheckStatus.error &&
              s.errorMessage == '링크 체크에 실패했습니다',
        ),
      ],
    );

    test('검사 중 cancel() → cancelled 상태로 전환', () async {
      // getAllLinks 가 지연되는 동안 cancel() 호출
      final completer = Completer<List<LocalLink>>();
      when(repo.getAllLinks()).thenAnswer((_) => completer.future);

      final cubit = LinkCheckCubit(linkRepository: repo);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.status, LinkCheckStatus.checking);

      cubit.cancel();
      expect(cubit.state.status, LinkCheckStatus.cancelled);

      // 이후 getAllLinks 가 완료돼도 상태는 cancelled 유지
      completer.complete(const []);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.status, LinkCheckStatus.cancelled);

      await cubit.close();
    });

    test('cancel() 은 검사 중이 아니면 no-op', () {
      when(repo.getAllLinks()).thenAnswer((_) async => const []);
      final cubit = LinkCheckCubit(linkRepository: repo, autoStart: false);

      expect(cubit.state.status, LinkCheckStatus.initial);
      cubit.cancel();
      expect(cubit.state.status, LinkCheckStatus.initial);

      cubit.close();
    });

    blocTest<LinkCheckCubit, LinkCheckState>(
      'deleteBrokenLink 후 목록에서 제거',
      setUp: () {
        when(repo.deleteLink(any)).thenAnswer((_) async => 1);
      },
      build: () => LinkCheckCubit(linkRepository: repo, autoStart: false),
      seed: () => const LinkCheckState(
        status: LinkCheckStatus.done,
        brokenLinks: [
          BrokenLink(linkId: 1, url: 'https://a.com'),
          BrokenLink(linkId: 2, url: 'https://b.com'),
        ],
      ),
      act: (cubit) => cubit.deleteBrokenLink(1),
      expect: () => [
        predicate<LinkCheckState>(
          (s) =>
              s.status == LinkCheckStatus.done &&
              s.brokenLinks.length == 1 &&
              s.brokenLinks.first.linkId == 2,
        ),
      ],
      verify: (_) {
        verify(repo.deleteLink(1)).called(1);
      },
    );
  });
}



