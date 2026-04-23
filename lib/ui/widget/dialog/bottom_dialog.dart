import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_selected_folder_cubit.dart';
import 'package:ac_project_app/cubits/folders/local_folders_cubit.dart';
import 'package:ac_project_app/cubits/links/local_links_from_folder_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/provider/check_clipboard_link.dart';
import 'package:ac_project_app/provider/recent_folders_repository.dart';
import 'package:ac_project_app/ui/widget/add_folder/folder_add_title.dart';
import 'package:ac_project_app/ui/widget/folder/pick_folder_sheet.dart';
import 'package:ac_project_app/ui/widget/folder/show_create_folder_sheet.dart';
import 'package:ac_project_app/ui/widget/add_folder/horizontal_folder_list.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/dialog/center_dialog.dart';
import 'package:ac_project_app/ui/widget/move_to_my_folder_dialog.dart';
import 'package:ac_project_app/ui/widget/rename_folder/show_rename_folder_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      final children = [
        BottomListItem(
          '공유',
          callback: () {
            setClipboardLink(link.url);
            Share.share(
              link.url ?? '',
              subject: link.title,
            );
          },
        ),
        BottomListItem(
          '링크 삭제',
          callback: () {
            getIt<LocalLinkRepository>().deleteLink(link.id!).then((count) {
              Navigator.pop(context);
              if (popCallback != null) {
                popCallback.call();
              } else {
                Navigator.pop(parentContext, 'deleted');
              }
              if (count > 0) {
                showBottomToast(
                  context: context,
                  '링크가 삭제되었어요!',
                );
              }
            });
          },
        ),
        BottomListItem(
          '폴더 이동',
          callback: () {
            showChangeFolderDialog(
              link,
              context,
            );
          },
        ),
      ];
      return Wrap(
        children: [
          DecoratedBox(
            decoration: DialogDecoration(),
            child: Padding(
              padding: EdgeInsets.only(
                top: 29.w,
                bottom: Platform.isAndroid ? MediaQuery.of(context).padding.bottom : 16.w,
              ),
              child: Column(
                children: [
                  buildTitle(context, '링크 옵션'),
                  Container(
                    margin: EdgeInsets.only(
                      top: 17.w,
                      left: 6.w,
                      right: 6.w,
                      bottom: 20.w,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
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
            create: (_) => LocalFoldersCubit(excludeUnclassified: true),
            child: BlocBuilder<LocalFoldersCubit, FoldersState>(
              builder: (foldersContext, state) {
                return DecoratedBox(
                  decoration: DialogDecoration(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 29.w,
                      bottom: (Platform.isAndroid ? MediaQuery.of(context).padding.bottom : 16.w) + 30.w,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTitle(context, '이동할 폴더를 선택해주세요', titleLeft: 24.w),
                        Container(
                          margin: EdgeInsets.only(top: 17.w, bottom: 20.w),
                          child: Divider(
                            height: 1.w,
                            thickness: 1.w,
                            color: grey100,
                          ),
                        ),
                        if (state is FolderLoadedState)
                          Container(
                            margin: EdgeInsets.only(left: 24.w),
                            child: buildFolderSelectTitle(
                              foldersContext,
                              '폴더 목록',
                              state.folders,
                            ),
                          ),
                        Container(
                          margin: EdgeInsets.only(left: 24.w),
                          child: buildFolderList(
                            folderContext: foldersContext,
                            state: state,
                            callback: (_, folder) {
                              getIt<LocalLinkRepository>().moveLink(link.id!, folder.id!).then((count) {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                Navigator.pop(context, 'changed');
                                if (count > 0) {
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
      final children = [
        BottomListItem(
          '공유',
          callback: () {
            setClipboardLink(link.url);
            Share.share(
              link.url ?? '',
              subject: link.title,
            );
          },
        ),
        BottomListItem(
          '내 폴더 담기',
          callback: () {
            moveToMyFolderDialog(parentContext, link);
          },
        ),
      ];
      return Wrap(
        children: [
          DecoratedBox(
            decoration: DialogDecoration(),
            child: Padding(
              padding: EdgeInsets.only(
                top: 29.w,
                bottom: Platform.isAndroid ? MediaQuery.of(context).viewInsets.bottom : 4.w,
              ),
              child: Column(
                children: [
                  buildTitle(context, '링크 옵션'),
                  Container(
                    margin: EdgeInsets.only(
                      top: 17.w,
                      left: 6.w,
                      right: 6.w,
                      bottom: 20.w,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
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
    margin: EdgeInsets.only(left: titleLeft ?? 30.w, right: 20.w),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(
            color: blackBold,
            fontSize: 20.sp,
            letterSpacing: -0.3.w,
            fontWeight: FontWeight.bold,
          ),
        ),
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Icons.close_rounded,
            size: 24.w,
          ),
        ),
      ],
    ),
  );
}

Widget BottomListItem(String text, {required void Function() callback}) {
  return InkWell(
    onTap: callback,
    highlightColor: grey100,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(10.w),
        ),
        color: Colors.transparent,
      ),
      padding: EdgeInsets.only(
        top: 14.w,
        bottom: 14.w,
        left: 24.w,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: blackBold,
            fontWeight: FontWeight.w500,
            fontSize: 16.sp,
          ),
        ),
      ),
    ),
  );
}

BoxDecoration DialogDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(20.w),
      topRight: Radius.circular(20.w),
    ),
  );
}

void showFolderOptionsDialog(
    List<Folder> folders,
    Folder currFolder,
    BuildContext parentContext, {
      bool fromLinkView = false,
    }) {
  showModalBottomSheet<void>(
    backgroundColor: Colors.transparent,
    context: parentContext,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Wrap(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.w),
                topRight: Radius.circular(20.w),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: 29.w,
                bottom: Platform.isAndroid ? MediaQuery.of(context).padding.bottom : 0,
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 30.w, right: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '폴더 옵션',
                          style: TextStyle(
                            color: grey800,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close_rounded,
                            size: 24.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                      top: 17.w,
                      left: 6.w,
                      right: 6.w,
                      bottom: 20.w,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BottomListItem(
                          '하위 폴더 추가',
                          callback: () async {
                            Navigator.pop(context); // 옵션 시트 먼저 닫기
                            final newId = await showCreateFolderSheet(
                              parentContext,
                              initialParentId: currFolder.id,
                            );
                            if (newId == null || !parentContext.mounted) return;
                            showBottomToast(
                              context: parentContext,
                              "'${currFolder.name}' 아래에 폴더가 생성되었어요!",
                            );
                            parentContext
                                .read<LocalFoldersCubit>()
                                .getFolders();
                            if (fromLinkView) {
                              parentContext
                                  .read<LocalLinksFromFolderCubit>()
                                  .refresh();
                            }
                          },
                        ),
                        BottomListItem(
                          '폴더명 변경',
                          callback: () {
                            changeFolderName(
                              parentContext,
                              folders,
                              currFolder,
                            );
                          },
                        ),
                        BottomListItem(
                          '폴더 이동',
                          callback: () {
                            Navigator.pop(context);
                            moveFolderAction(parentContext, currFolder);
                          },
                        ),
                        BottomListItem(
                          '폴더 삭제',
                          callback: () {
                            deleteFolderDialog(
                              parentContext,
                              currFolder,
                              callback: () {
                                if (fromLinkView) {
                                  Navigator.pop(parentContext);
                                }
                              },
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

Future<void> moveFolderAction(
  BuildContext parentContext,
  Folder currFolder,
) async {
  final folderId = currFolder.id;
  if (folderId == null) return;
  final folderRepo = getIt<LocalFolderRepository>();

  // 자기 + 후손은 이동 대상 부모로 선택 불가
  final descendants = await folderRepo.getAllDescendants(folderId);
  final excludeIds = <int>{
    for (final f in descendants)
      if (f.id != null) f.id!,
  };

  if (!parentContext.mounted) return;
  final newParentId = await showPickFolderSheet(
    context: parentContext,
    title: '폴더 이동',
    excludeIds: excludeIds,
    actionLabel: '이동',
  );

  if (newParentId == null) return;

  final ok = await folderRepo.moveFolder(folderId, newParentId);
  if (!parentContext.mounted) return;
  if (ok) {
    await const RecentFoldersRepository().record(newParentId);
    if (!parentContext.mounted) return;
    parentContext.read<LocalFoldersCubit>().getFolders();
    showBottomToast('폴더를 이동했어요', context: parentContext);
  } else {
    showBottomToast('이동할 수 없는 폴더입니다', context: parentContext);
  }
}

void changeFolderName(
    BuildContext context,
    List<Folder> folders,
    Folder currFolder,
    ) {
  showRenameFolderDialog(
    context,
    currFolder: currFolder,
    folders: folders,
  ).then((name) {
    name = name ?? '';
    if (name.isNotEmpty) {
      Navigator.pop(context, true);
      context.read<LocalFoldersCubit>().getFolders();
      context.read<GetSelectedFolderCubit>().update(currFolder.copyWith(name: name));
    }
  });
}
