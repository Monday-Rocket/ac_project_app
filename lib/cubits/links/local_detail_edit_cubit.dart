import 'package:ac_project_app/cubits/links/edit_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 로컬 DB를 사용하는 링크 상세/편집 Cubit
/// DetailEditCubit을 대체
class LocalDetailEditCubit extends Cubit<EditState> {
  LocalDetailEditCubit(Object? argument) : super(EditState(EditStateType.view)) {
    if (argument is Map) {
      final link = (argument['link'] ?? const Link()) as Link;
      textController.text = link.describe ?? '';
    }
  }

  final LocalLinkRepository _linkRepository = getIt();
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
}
