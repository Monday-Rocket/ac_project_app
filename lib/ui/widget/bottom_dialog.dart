import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folder_name_cubit.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/report/report_type.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/my_folder/folder_visible_state.dart';
import 'package:ac_project_app/ui/widget/add_folder/folder_add_title.dart';
import 'package:ac_project_app/ui/widget/add_folder/horizontal_folder_list.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

Future<bool?> showMyLinkOptionsDialog(
  Link link,
  BuildContext parentContext, {
  void Function()? popCallback,
}) {
  return showModalBottomSheet<bool?>(
    backgroundColor: Colors.transparent,
    context: parentContext,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Wrap(
        children: [
          DecoratedBox(
            decoration: _dialogDecoration(),
            child: Padding(
              padding: EdgeInsets.only(
                top: 29,
                bottom: Platform.isAndroid
                    ? MediaQuery.of(context).padding.bottom
                    : 16,
              ),
              child: Column(
                children: [
                  buildTitle(context, '링크 옵션'),
                  Container(
                    margin: const EdgeInsets.only(
                      top: 17,
                      left: 6,
                      right: 6,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildItem(
                          '공유',
                          callback: () {
                            Share.share(
                              link.url ?? '',
                              subject: link.title,
                            );
                            Clipboard.setData(
                              ClipboardData(text: link.url ?? ''),
                            ).then(
                              (value) => showBottomToast(
                                context: context,
                                '링크 주소가 복사 되었어요!',
                              ),
                            );
                          },
                        ),
                        _buildItem(
                          '링크 삭제',
                          callback: () {
                            LinkApi().deleteLink(link).then((result) {
                              Navigator.pop(context);
                              if (popCallback != null) {
                                popCallback.call();
                              } else {
                                Navigator.pop(parentContext, 'deleted');
                              }
                              if (result) {
                                showBottomToast(
                                  context: context,
                                  '링크가 삭제되었어요!',
                                );
                              }
                            });
                          },
                        ),
                        _buildItem(
                          '폴더 이동',
                          callback: () {
                            showChangeFolderDialog(
                              link,
                              parentContext,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<bool?> showChangeFolderDialog(Link link, BuildContext parentContext) {
  return showModalBottomSheet<bool?>(
    backgroundColor: Colors.transparent,
    context: parentContext,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Wrap(
        children: [
          BlocProvider(
            create: (_) => GetFoldersCubit(excludeUnclassified: true),
            child: BlocBuilder<GetFoldersCubit, FoldersState>(
              builder: (foldersContext, state) {
                return DecoratedBox(
                  decoration: _dialogDecoration(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 29,
                      bottom: (Platform.isAndroid
                              ? MediaQuery.of(context).padding.bottom
                              : 16) +
                          30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTitle(context, '이동할 폴더를 선택해주세요', titleLeft: 24),
                        Container(
                          margin: const EdgeInsets.only(top: 17, bottom: 20),
                          child: const Divider(
                            height: 1,
                            thickness: 1,
                            color: grey100,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 24),
                          child:
                              buildFolderSelectTitle(foldersContext, '폴더 목록'),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 24),
                          child: buildFolderList(
                            folderContext: foldersContext,
                            state: state,
                            callback: (_, folderId) {
                              LinkApi()
                                  .changeFolder(link, folderId)
                                  .then((result) {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                if (result) {
                                  showBottomToast(
                                    context: context,
                                    '선택한 폴더로 이동 완료!',
                                  );
                                } else {
                                  showBottomToast(
                                    context: context,
                                    '폴더 이동 실패!',
                                  );
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

Future<bool?> showLinkOptionsDialog(
  Link link,
  BuildContext parentContext, {
  void Function()? callback,
}) {
  return showModalBottomSheet<bool?>(
    backgroundColor: Colors.transparent,
    context: parentContext,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Wrap(
        children: [
          DecoratedBox(
            decoration: _dialogDecoration(),
            child: Padding(
              padding: EdgeInsets.only(
                top: 29,
                bottom: Platform.isAndroid
                    ? MediaQuery.of(context).padding.bottom
                    : 16,
              ),
              child: Column(
                children: [
                  buildTitle(context, '링크 옵션'),
                  Container(
                    margin: const EdgeInsets.only(
                      top: 17,
                      left: 6,
                      right: 6,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildItem(
                          '공유',
                          callback: () => Share.share(
                            link.url ?? '',
                            subject: link.title,
                          ),
                        ),
                        _buildItem(
                          '내 폴더 담기',
                          callback: () {
                            Navigator.pushNamed(
                              context,
                              Routes.upload,
                              arguments: {
                                'url': link.url,
                                'isCopied': true,
                              },
                            ).then((value) {
                              Navigator.pop(context);
                              callback?.call();
                              Navigator.pushReplacementNamed(
                                context,
                                Routes.home,
                                arguments: {
                                  'index': 2,
                                },
                              );
                            });
                          },
                        ),
                        _buildItem(
                          '신고하기',
                          callback: () {
                            Navigator.pushNamed(
                              context,
                              Routes.report,
                              arguments: {
                                'type': ReportType.post,
                                'id': link.id,
                                'name': link.title,
                              },
                            ).then((value) {
                              Navigator.pop(context);
                              callback?.call();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<bool?> showUserOptionDialog(
  BuildContext parentContext,
  DetailUser user, {
  void Function()? callback,
}) {
  return showModalBottomSheet<bool?>(
    backgroundColor: Colors.transparent,
    context: parentContext,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Wrap(
        children: [
          DecoratedBox(
            decoration: _dialogDecoration(),
            child: Padding(
              padding: EdgeInsets.only(
                top: 29,
                bottom: Platform.isAndroid
                    ? MediaQuery.of(context).padding.bottom
                    : 16,
              ),
              child: Column(
                children: [
                  buildTitle(context, '사용자 옵션'),
                  Container(
                    margin: const EdgeInsets.only(
                      top: 17,
                      left: 6,
                      right: 6,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildItem(
                          '신고하기',
                          callback: () {
                            Navigator.pushNamed(
                              parentContext,
                              Routes.report,
                              arguments: {
                                'type': ReportType.user,
                                'id': user.id,
                                'name': user.nickname,
                              },
                            ).then((_) {
                              Navigator.pop(context);
                              callback?.call();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

Container buildTitle(BuildContext context, String title, {double? titleLeft}) {
  return Container(
    margin: EdgeInsets.only(left: titleLeft ?? 30, right: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: blackBold,
            fontSize: 20,
            letterSpacing: -0.3,
            fontWeight: FontWeight.bold,
          ),
        ),
        InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.close_rounded,
            size: 24,
          ),
        ),
      ],
    ),
  );
}

Widget _buildItem(String text, {required void Function() callback}) {
  return InkWell(
    onTap: callback,
    highlightColor: grey100,
    child: Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
        color: Colors.transparent,
      ),
      padding: const EdgeInsets.only(
        top: 14,
        bottom: 14,
        left: 24,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: blackBold,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _dialogDecoration() {
  return const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    ),
  );
}

void saveEmptyFolder(
  BuildContext context,
  BuildContext parentContext,
  String folderName,
  FolderVisibleState visibleState, {
  void Function(BuildContext context, List<Folder> folders, int index)?
      moveToMyLinksView,
  void Function()? callback,
  bool? hasNotUnclassified,
}) {
  if (folderName.isEmpty) {
    return;
  }

  final folder = Folder(
    name: folderName,
    visible: visibleState == FolderVisibleState.visible,
  );

  context.read<FolderNameCubit>().add(folder).then((result) {
    if (result) {
      Navigator.pop(context);
      showBottomToast(context: context, '새로운 폴더가 생성되었어요!');

      if (hasNotUnclassified ?? false) {
        parentContext
            .read<GetFoldersCubit>()
            .getFoldersWithoutUnclassified()
            .then((_) {
          runCallback(
            parentContext,
            moveToMyLinksView: moveToMyLinksView,
            callback: callback,
          );
        });
      } else {
        parentContext.read<GetFoldersCubit>().getFolders().then((_) {
          runCallback(
            parentContext,
            moveToMyLinksView: moveToMyLinksView,
            callback: callback,
          );
        });
      }
    } else {
      showBottomToast(context: context, '중복된 폴더 이름입니다!');
    }
  });
}

void runCallback(
  BuildContext parentContext, {
  void Function(BuildContext context, List<Folder> folders, int index)?
      moveToMyLinksView,
  void Function()? callback,
}) {
  final folders = parentContext.read<GetFoldersCubit>().folders;
  moveToMyLinksView?.call(parentContext, folders, folders.length - 1);
  callback?.call();
}
