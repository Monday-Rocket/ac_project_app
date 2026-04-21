import 'dart:async';

import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/util/link_checker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum LinkCheckStatus { initial, checking, empty, done, cancelled, error }

class BrokenLink {
  final int linkId;
  final String url;
  final String? title;
  final int? status;

  const BrokenLink({
    required this.linkId,
    required this.url,
    this.title,
    this.status,
  });
}

class LinkCheckState {
  final LinkCheckStatus status;
  final List<BrokenLink> brokenLinks;
  final int checked;
  final int total;
  final String? errorMessage;

  const LinkCheckState({
    this.status = LinkCheckStatus.initial,
    this.brokenLinks = const [],
    this.checked = 0,
    this.total = 0,
    this.errorMessage,
  });

  String get progressText => '$checked/$total개 검사 중...';
  String get doneText => '깨진 링크 ${brokenLinks.length}건을 찾았어요';

  LinkCheckState copyWith({
    LinkCheckStatus? status,
    List<BrokenLink>? brokenLinks,
    int? checked,
    int? total,
    String? errorMessage,
  }) {
    return LinkCheckState(
      status: status ?? this.status,
      brokenLinks: brokenLinks ?? this.brokenLinks,
      checked: checked ?? this.checked,
      total: total ?? this.total,
      errorMessage: errorMessage,
    );
  }
}

class LinkCheckCubit extends Cubit<LinkCheckState> {
  final LocalLinkRepository _linkRepository;
  LinkCheckCancelToken? _cancelToken;

  LinkCheckCubit({
    required LocalLinkRepository linkRepository,
    bool autoStart = true,
  })  : _linkRepository = linkRepository,
        super(const LinkCheckState()) {
    if (autoStart) {
      unawaited(checkAllLinks());
    }
  }

  Future<void> checkAllLinks() async {
    final token = LinkCheckCancelToken();
    _cancelToken = token;
    emit(const LinkCheckState(status: LinkCheckStatus.checking));

    try {
      final links = await _linkRepository.getAllLinks();

      if (token.isCancelled) {
        if (!isClosed) emit(state.copyWith(status: LinkCheckStatus.cancelled));
        return;
      }

      if (links.isEmpty) {
        emit(const LinkCheckState(status: LinkCheckStatus.empty));
        return;
      }

      final urls = links.map((l) => l.url).toList();
      emit(state.copyWith(total: urls.length));

      final results = await LinkChecker.checkLinks(
        urls,
        cancelToken: token,
        onProgress: (checked, total) {
          if (isClosed || token.isCancelled) return;
          emit(state.copyWith(checked: checked, total: total));
        },
      );

      if (isClosed) return;

      if (token.isCancelled) {
        emit(state.copyWith(status: LinkCheckStatus.cancelled));
        return;
      }

      final brokenLinks = results
          .where((r) => !r.ok)
          .map((r) {
            final link = links.firstWhere((l) => l.url == r.url);
            return BrokenLink(
              linkId: link.id!,
              url: r.url,
              title: (link.title != null && link.title!.isNotEmpty)
                  ? link.title
                  : null,
              status: r.status,
            );
          })
          .toList();

      emit(state.copyWith(
        status: LinkCheckStatus.done,
        brokenLinks: brokenLinks,
      ));
    } on Exception catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        status: LinkCheckStatus.error,
        errorMessage: '링크 체크에 실패했습니다',
      ));
    } finally {
      if (identical(_cancelToken, token)) _cancelToken = null;
    }
  }

  /// 검사 중지. 이미 검사 중이 아니면 no-op.
  void cancel() {
    final token = _cancelToken;
    if (token == null || token.isCancelled) return;
    token.cancel();
    if (!isClosed && state.status == LinkCheckStatus.checking) {
      emit(state.copyWith(status: LinkCheckStatus.cancelled));
    }
  }

  Future<void> deleteBrokenLink(int linkId) async {
    await _linkRepository.deleteLink(linkId);
    final updated = state.brokenLinks
        .where((l) => l.linkId != linkId)
        .toList();
    emit(state.copyWith(brokenLinks: updated));
  }

  void reset() {
    emit(const LinkCheckState());
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel();
    return super.close();
  }
}
