import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folder_name_cubit.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_selected_folder_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/report/report_type.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/provider/check_clipboard_link.dart';
import 'package:ac_project_app/provider/kakao/kakao.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/my_folder/folder_visible_state.dart';
import 'package:ac_project_app/ui/widget/add_folder/folder_add_title.dart';
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
  bool? linkVisible,
}) {
  return showModalBottomSheet<bool?>(
    backgroundColor: Colors.transparent,
    context: parentContext,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Wrap(
        children: [
          DecoratedBox(
            decoration: DialogDecoration(),
            child: Padding(
              padding: EdgeInsets.only(
                top: 29.w,
                bottom: Platform.isAndroid
                    ? MediaQuery.of(context).padding.bottom
                    : 16.w,
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
                      children: [
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
                          '카카오톡 공유',
                          callback: () {
                            if (linkVisible ?? true) {
                              Kakao.sendKakaoLinkShare(link);
                            } else {
                              showPopUp(
                                title: '폴더를 공개해 주세요',
                                content: '카카오톡 공유는\n공개 폴더로 전환 후 가능해요!',
                                parentContext: parentContext,
                                callback: () => Navigator.pop(context),
                                icon: true,
                                iconImage: Assets.images.icLockColor
                                    .image(width: 27.w, height: 27.w),
                              );
                            }
                          },
                        ),
                        BottomListItem(
                          '링크 삭제',
                          callback: () {
                            getIt<LinkApi>().deleteLink(link).then((result) {
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
                        BottomListItem(
                          '폴더 이동',
                          callback: () {
                            showChangeFolderDialog(
                              link,
                              context,
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
                  decoration: DialogDecoration(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 29.w,
                      bottom: (Platform.isAndroid
                              ? MediaQuery.of(context).padding.bottom
                              : 16.w) +
                          30.w,
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
                              getIt<LinkApi>()
                                  .changeFolder(link, folder.id!)
                                  .then((result) {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                Navigator.pop(context, 'changed');
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
            decoration: DialogDecoration(),
            child: Padding(
              padding: EdgeInsets.only(
                top: 29.w,
                bottom: Platform.isAndroid
                    ? MediaQuery.of(context).viewInsets.bottom
                    : 4.w,
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
                      children: [
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
                          '카카오톡 공유',
                          callback: () {
                            Kakao.sendKakaoLinkShare(link);
                          },
                        ),
                        BottomListItem(
                          '내 폴더 담기',
                          callback: () {
                            moveToMyFolderDialog(parentContext, link);
                          },
                        ),
                        BottomListItem(
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
            decoration: DialogDecoration(),
            child: Padding(
              padding: EdgeInsets.only(
                top: 29.w,
                bottom: Platform.isAndroid
                    ? MediaQuery.of(context).padding.bottom
                    : 16.w,
              ),
              child: Column(
                children: [
                  buildTitle(context, '사용자 옵션'),
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

void showFolderOptionsDialog(
  List<Folder> folders,
  Folder currFolder,
  BuildContext parentContext, {
  bool fromLinkView = false,
}) {
  final visible = currFolder.visible ?? false;
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
                bottom: Platform.isAndroid
                    ? MediaQuery.of(context).padding.bottom
                    : 0,
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
                          visible ? '비공개로 전환' : '공개로 전환',
                          callback: () {
                            changeFolderVisible(
                              parentContext,
                              currFolder,
                            );
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
                        BottomListItem(
                          '카카오톡 폴더 공유',
                          callback: () {
                            final profileInfoCubit =
                                getIt<GetProfileInfoCubit>();
                            if (profileInfoCubit.state is ProfileLoadedState) {
                              final profile =
                                  (profileInfoCubit.state as ProfileLoadedState)
                                      .profile;

                              if (currFolder.visible ?? false) {
                                Kakao.sendFolderKakaoShare(
                                  currFolder,
                                  profile,
                                );
                              } else {
                                showPopUp(
                                  title: '폴더를 공개해 주세요',
                                  content: '카카오톡 폴더 공유는\n공개 폴더로 전환 후 가능해요!',
                                  parentContext: parentContext,
                                  callback: () => Navigator.pop(context),
                                  icon: true,
                                  iconImage: Assets.images.icLockColor
                                      .image(width: 27.w, height: 27.w),
                                );
                              }
                            }
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

void showSharedFolderOptionsDialog(
  BuildContext parentContext, {
  bool isAdmin = false,
}) {
  Column SharedFolderMenu() {
    if (isAdmin) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BottomListItem(
            '공유하기',
            callback: () {
              // TODO
            },
          ),
          BottomListItem(
            '폴더 설정',
            callback: () {},
          ),
          BottomListItem(
            '멤버 관리',
            callback: () {},
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BottomListItem(
            '공유하기',
            callback: () {
              // TODO
            },
          ),
          BottomListItem(
            '폴더 나가기',
            callback: () {},
          ),
        ],
      );
    }
  }

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
                bottom: Platform.isAndroid
                    ? MediaQuery.of(context).padding.bottom
                    : 0,
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 30.w, right: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '공유 폴더',
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
                    child: SharedFolderMenu(),
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


void changeFolderVisible(BuildContext context, Folder folder) {
  context.read<GetFoldersCubit>().transferVisible(folder).then((value) {
    Navigator.pop(context);
    if (value) {
      context
          .read<GetSelectedFolderCubit>()
          .update(folder.copyWith(visible: !(folder.visible ?? false)));
    }
  });
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
      context.read<GetFoldersCubit>().getFolders();
      context
          .read<GetSelectedFolderCubit>()
          .update(currFolder.copyWith(name: name));
    }
  });
}
