import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folder_name_cubit.dart';
import 'package:ac_project_app/cubits/folders/folder_visible_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/links/delete_link.dart';
import 'package:ac_project_app/cubits/sign_up/button_state_cubit.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/report/report_type.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/my_folder/folder_visible_state.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

Future<bool?> showMyLinkOptionsDialog(Link link, BuildContext parentContext, {void Function()? popCallback}) {
  return showModalBottomSheet<bool?>(
    backgroundColor: Colors.transparent,
    context: parentContext,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Wrap(
        children: [
          StatefulBuilder(
            builder: (context, setState) {
              return DecoratedBox(
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
                            InkWell(
                              onTap: () {
                                Share.share(
                                  link.url ?? '',
                                  subject: link.title,
                                );
                                Clipboard.setData(
                                  ClipboardData(text: link.url ?? ''),
                                ).then(
                                  (value) => showBottomToast('링크 주소가 복사 되었어요!'),
                                );
                              },
                              highlightColor: grey100,
                              child: buildItem('공유'),
                            ),
                            InkWell(
                              onTap: () {
                                DeleteLink.delete(link).then((result) {
                                  Navigator.pop(context);
                                  if (popCallback != null) {
                                    popCallback.call();
                                  } else {
                                    Navigator.pop(parentContext, 'deleted');
                                  }
                                  if (result) {
                                    showBottomToast('링크가 삭제되었어요!');
                                  }
                                });
                              },
                              child: buildItem('링크 삭제'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
          StatefulBuilder(
            builder: (context, setState) {
              return DecoratedBox(
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
                            InkWell(
                              onTap: () => Share.share(
                                link.url ?? '',
                                subject: link.title,
                              ),
                              highlightColor: grey100,
                              child: buildItem('공유'),
                            ),
                            InkWell(
                              onTap: () {
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
                              child: buildItem('내 폴더 담기'),
                            ),
                            InkWell(
                              onTap: () {
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
                              child: buildItem('신고하기'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
          StatefulBuilder(
            builder: (context, setState) {
              return DecoratedBox(
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
                            InkWell(
                              onTap: () {
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
                              child: buildItem('신고하기'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}

Container buildTitle(BuildContext context, String title) {
  return Container(
    margin: const EdgeInsets.only(left: 30, right: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

Container buildItem(String text) {
  return Container(
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

Future<bool?> showAddFolderDialog(
  BuildContext parentContext, {
  void Function(BuildContext context, List<Folder> folders, int index)?
      moveToMyLinksView,
  void Function()? callback,
  bool? isFromUpload,
}) async {
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<bool>(
    backgroundColor: Colors.transparent,
    context: parentContext,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ButtonStateCubit(),
          ),
          BlocProvider(
            create: (_) => FolderNameCubit(),
          ),
          BlocProvider(
            create: (_) => FolderVisibleCubit(),
          ),
        ],
        child: Wrap(
          children: [
            KeyboardDismissOnTap(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 30,
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: BlocBuilder<FolderVisibleCubit, FolderVisibleState>(
                    builder: (context, visibleState) {
                      return Column(
                        children: [
                          Stack(
                            children: [
                              Center(
                                child: const Text('새로운 폴더').bold().fontSize(20),
                              ),
                              BlocBuilder<ButtonStateCubit, ButtonState>(
                                builder: (context, state) {
                                  return Container(
                                    alignment: Alignment.topRight,
                                    child: InkWell(
                                      onTap: () => saveEmptyFolder(
                                        context,
                                        parentContext,
                                        context.read<FolderNameCubit>().state,
                                        visibleState,
                                        moveToMyLinksView: moveToMyLinksView,
                                        callback: callback,
                                        isFromUpload: isFromUpload,
                                      ),
                                      child: Text(
                                        '완료',
                                        style: TextStyle(
                                          color: state == ButtonState.disabled
                                              ? grey300
                                              : grey800,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 60),
                                child: Form(
                                  key: formKey,
                                  child: TextFormField(
                                    autofocus: true,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: grey800,
                                    ),
                                    cursorColor: primary600,
                                    decoration: InputDecoration(
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: primary800,
                                          width: 2,
                                        ),
                                      ),
                                      suffix: context
                                              .read<FolderNameCubit>()
                                              .state
                                              .isEmpty
                                          ? const SizedBox.shrink()
                                          : InkWell(
                                              onTap: () {
                                                context
                                                    .read<FolderNameCubit>()
                                                    .update('');
                                                context
                                                    .read<ButtonStateCubit>()
                                                    .disable();
                                              },
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 19,
                                              ),
                                            ),
                                      hintStyle: const TextStyle(
                                        color: grey400,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      hintText: '새로운 폴더 이름',
                                    ),
                                    validator: (value) {
                                      return null;
                                    },
                                    onChanged: (String? value) {
                                      if (value?.isEmpty ?? true) {
                                        context
                                            .read<ButtonStateCubit>()
                                            .disable();
                                      } else {
                                        context
                                            .read<ButtonStateCubit>()
                                            .enable();
                                        context
                                            .read<FolderNameCubit>()
                                            .update(value!);
                                      }
                                    },
                                    onFieldSubmitted: (value) {
                                      saveEmptyFolder(
                                        context,
                                        parentContext,
                                        value,
                                        visibleState,
                                        moveToMyLinksView: moveToMyLinksView,
                                        callback: callback,
                                        isFromUpload: isFromUpload,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                const Text(
                                  '비공개 폴더',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: grey800,
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                InkWell(
                                  onTap:
                                      context.read<FolderVisibleCubit>().toggle,
                                  child: visibleState ==
                                          FolderVisibleState.invisible
                                      ? SvgPicture.asset(
                                          'assets/images/toggle_on.svg',
                                        )
                                      : SvgPicture.asset(
                                          'assets/images/toggle_off.svg',
                                        ),
                                ),
                              ],
                            ),
                          ),
                          BlocBuilder<ButtonStateCubit, ButtonState>(
                            builder: (context, state) {
                              return Container(
                                margin: EdgeInsets.only(
                                  top: 50,
                                  bottom: Platform.isAndroid
                                      ? MediaQuery.of(context).padding.bottom
                                      : 16,
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(55),
                                    backgroundColor:
                                        state == ButtonState.disabled
                                            ? secondary
                                            : primary600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => saveEmptyFolder(
                                    context,
                                    parentContext,
                                    context.read<FolderNameCubit>().state,
                                    visibleState,
                                    moveToMyLinksView: moveToMyLinksView,
                                    callback: callback,
                                    isFromUpload: isFromUpload,
                                  ),
                                  child: const Text(
                                    '폴더에 저장하기',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textWidthBasis: TextWidthBasis.parent,
                                  ),
                                ),
                              );
                            },
                          )
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
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
  bool? isFromUpload,
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
      showBottomToast('새로운 폴더가 생성되었어요!');

      if (isFromUpload ?? false) {
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
      showBottomToast('중복된 폴더 이름입니다!');
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
