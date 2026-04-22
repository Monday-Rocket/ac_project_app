import 'package:ac_project_app/cubits/links/edit_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/url_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

/// URL → Metadata 조회 함수. 테스트에서 주입하기 위해 typedef 로 분리.
typedef MetadataLoader = Future<Metadata> Function(String url);

/// 로컬 DB를 사용하는 링크 상세/편집 Cubit
/// DetailEditCubit을 대체
class LocalDetailEditCubit extends Cubit<EditState> {
  LocalDetailEditCubit(
    Object? argument, {
    MetadataLoader? metadataLoader,
  })  : _metadataLoader = metadataLoader ?? UrlLoader.loadData,
        super(EditState(EditStateType.view)) {
    if (argument is Map) {
      final link = (argument['link'] ?? const Link()) as Link;
      textController.text = link.describe ?? '';
    }
  }

  final LocalLinkRepository _linkRepository = getIt();
  final MetadataLoader _metadataLoader;
  final textController = TextEditingController();

  void toggle() {
    if (state.type == EditStateType.view) {
      emit(state.copyWith(type: EditStateType.edit));
    } else {
      emit(state.copyWith(type: EditStateType.view));
    }
  }

  void toggleEdit(Link link) {
    emit(state.copyWith(type: EditStateType.editedView, link: link));
  }

  Future<Link> saveComment(Link link) async {
    try {
      if (link.id == null) return link;

      final existingLink = await _linkRepository.getLinkById(link.id!);
      if (existingLink == null) return link;

      final updatedLocalLink = LocalLink(
        id: existingLink.id,
        folderId: existingLink.folderId,
        url: existingLink.url,
        title: existingLink.title,
        image: existingLink.image,
        describe: textController.text,
        inflowType: existingLink.inflowType,
        createdAt: existingLink.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _linkRepository.updateLink(updatedLocalLink);
      return link.copyWith(describe: textController.text);
    } catch (e) {
      Log.e('LocalDetailEditCubit.saveComment error: $e');
      return link;
    }
  }

  /// 링크 삭제
  Future<bool> deleteLink(int linkId) async {
    try {
      await _linkRepository.deleteLink(linkId);
      return true;
    } catch (e) {
      Log.e('LocalDetailEditCubit.deleteLink error: $e');
      return false;
    }
  }

  /// 링크 폴더 이동
  Future<bool> moveLink(int linkId, int newFolderId) async {
    try {
      await _linkRepository.moveLink(linkId, newFolderId);
      return true;
    } catch (e) {
      Log.e('LocalDetailEditCubit.moveLink error: $e');
      return false;
    }
  }

  /// 링크 썸네일(og:image) 백필.
  ///
  /// DB 의 image 컬럼이 비어 있는 경우에만 원격 메타데이터를 조회하여
  /// og:image 를 DB 에 저장한다. 실패하면 조용히 무시한다.
  /// 상위 화면이 변경 사실을 감지할 수 있도록 성공 시
  /// EditStateType.editedView 로 emit 한다.
  Future<void> backfillImageIfMissing(Link link) async {
    final id = link.id;
    final url = link.url;
    final hasImage = link.image?.isNotEmpty ?? false;

    if (id == null || url == null || url.isEmpty || hasImage) return;

    try {
      final metadata = await _metadataLoader(url);
      final image = metadata.image;
      if (image == null || image.isEmpty) return;

      final existing = await _linkRepository.getLinkById(id);
      if (existing == null) return;

      final updated = LocalLink(
        id: existing.id,
        folderId: existing.folderId,
        url: existing.url,
        title: existing.title,
        image: image,
        describe: existing.describe,
        inflowType: existing.inflowType,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _linkRepository.updateLink(updated);

      if (isClosed) return;
      emit(
        state.copyWith(
          type: EditStateType.editedView,
          link: link.copyWith(image: image),
        ),
      );
    } catch (e) {
      Log.e('LocalDetailEditCubit.backfillImageIfMissing error: $e');
    }
  }
}
