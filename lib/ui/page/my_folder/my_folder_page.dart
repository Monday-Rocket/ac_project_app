// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';
import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folder_view_type_cubit.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/add_folder/show_add_folder_dialog.dart';
import 'package:ac_project_app/ui/widget/custom_reorderable_list_view.dart';
import 'package:ac_project_app/ui/widget/dialog/center_dialog.dart';
import 'package:ac_project_app/ui/widget/rename_folder/show_rename_folder_dialog.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyFolderPage extends StatefulWidget {
  const MyFolderPage({super.key});

  @override
  State<MyFolderPage> createState() => _MyFolderPageState();
}

class _MyFolderPageState extends State<MyFolderPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.detached) {
      Future.delayed(const Duration(milliseconds: 300), () {
        context.read<GetFoldersCubit>().getFolders().then((value) {
          setState(() {});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return BlocBuilder<FolderViewTypeCubit, FolderViewType>(
      builder: (context, folderViewType) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              Assets.images.myFolderBack.image(
                width: width,
                fit: BoxFit.fill,
              ),
              BlocBuilder<GetFoldersCubit, FoldersState>(
                builder: (getFolderContext, folderState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BlocBuilder<GetProfileInfoCubit, ProfileState>(
                        builder: (context, state) {
                          if (state is ProfileLoadedState) {
                            final profile = state.profile;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 105.w,
                                  height: 105.h,
                                  margin: EdgeInsetsDirectional.only(
                                    top: 90.h,
                                    bottom: 6.h,
                                  ),
                                  child: Image.asset(ProfileImage.makeImagePath(profile.profileImage)),
                                ),
                                Text(
                                  profile.nickname,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28.sp,
                                    color: const Color(0xff0e0e0e),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                      Container(
                        margin: EdgeInsetsDirectional.only(
                          top: 50.h,
                          start: 20,
                          end: 20,
                          bottom: 6.h,
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: grey100,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(7.r)),
                                ),
                                margin: EdgeInsets.only(right: 6.w),
                                child: TextField(
                                  textAlignVertical: TextAlignVertical.center,
                                  cursorColor: grey800,
                                  style: TextStyle(
                                    color: grey800,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                    ),
                                    prefixIcon: Assets.images.folderSearchIcon.image(),
                                  ),
                                  onChanged: (value) {
                                    context
                                        .read<GetFoldersCubit>()
                                        .filter(value);
                                  },
                                ),
                              ),
                            ),
                            if (folderState is FolderLoadedState)
                              InkWell(
                                onTap: () => showAddFolderDialog(
                                  context,
                                  moveToMyLinksView: moveToMyLinksView,
                                  folders: folderState.folders,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(6.r),
                                  child: SvgPicture.asset(
                                    Assets.images.btnAdd,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          if (folderState is FolderLoadingState) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (folderState is FolderErrorState) {
                            Log.e(folderState.props[0]);
                            return const Center(
                              child: Icon(Icons.close),
                            );
                          } else if (folderState is FolderLoadedState) {
                            if (folderState.folders.isEmpty) {
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    '등록된 폴더가 없습니다',
                                    style: TextStyle(
                                      color: grey300,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return buildListView(
                                folderState.folders,
                                context,
                              );
                            }
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void moveToMyLinksView(
    BuildContext context,
    List<Folder> folders,
    int index,
  ) {
    Navigator.pushNamed(
      context,
      Routes.myLinks,
      arguments: {
        'folders': folders,
        'tabIndex': index,
      },
    ).then((result) {
      context.read<GetFoldersCubit>().getFolders().then((value) {
        setState(() {});
      });
    });
  }

  Widget buildListView(List<Folder> folders, BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        child: RefreshIndicator(
          onRefresh: () async => context.read<GetFoldersCubit>().getFolders(),
          color: primary600,
          child: CustomReorderableListView.separated(
            shrinkWrap: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: folders.length,
            separatorBuilder: (ctx, index) => Divider(
              thickness: 1.h,
              height: 1.h,
              color: greyTab,
            ),
            itemBuilder: (ctx, index) {
              final folder = folders[index];
              final visible = folder.visible ?? true;
              final isNotClassified = folder.name == '미분류';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                key: Key('$index'),
                title: InkWell(
                  onTap: () {
                    moveToMyLinksView(context, folders, index);
                  },
                  child: Container(
                    margin:
                        EdgeInsets.symmetric(vertical: 20.h, horizontal: 4.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 69.w,
                              height: 63.h,
                              margin: EdgeInsets.only(right: 30.w),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(20.r),
                                    ),
                                    child: ColoredBox(
                                      color: grey100,
                                      child: folder.thumbnail != null &&
                                              (folder.thumbnail?.isNotEmpty ??
                                                  false)
                                          ? Image.network(
                                              folder.thumbnail!,
                                              width: 63.w,
                                              height: 63.h,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  emptyFolderView(),
                                            )
                                          : emptyFolderView(),
                                    ),
                                  ),
                                  if (!visible)
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Padding(
                                        padding:
                                            EdgeInsets.only(bottom: 3.h),
                                        child: Assets.images.icLockPng.image(),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120.w,
                                  child: Text(
                                    folder.name!,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                      color: blackBold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 6.h,
                                ),
                                Text(
                                  '링크 ${addCommasFrom(folder.links)}개',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: greyText,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                        if (isNotClassified)
                          const SizedBox.shrink()
                        else
                          InkWell(
                            onTap: () => showFolderOptionsDialog(
                              folders,
                              folder,
                              context,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(8.r),
                              child: SvgPicture.asset(Assets.images.more),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
            onReorder: (int oldIndex, int newIndex) {
              Log.i('old: $oldIndex, new: $newIndex');
              final item = folders.removeAt(oldIndex);
              folders.insert(newIndex, item);
            },
          ),
        ),
      ),
    );
  }

  Container emptyFolderView() {
    return Container(
      width: 63.w,
      height: 63.h,
      color: primary100,
      child: Center(
        child: SvgPicture.asset(
          Assets.images.folder,
          width: 24.w,
          height: 24.h,
        ),
      ),
    );
  }

  Future<bool?> showFolderOptionsDialog(
    List<Folder> folders,
    Folder currFolder,
    BuildContext parentContext,
  ) async {
    final visible = currFolder.visible ?? false;
    return showModalBottomSheet<bool?>(
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
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: 29.h,
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
                              size: 24.r,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        top: 17.h,
                        left: 6.w,
                        right: 6.w,
                        bottom: 20.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => changeFolderVisible(
                              parentContext,
                              currFolder,
                            ),
                            highlightColor: grey100,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10.r),
                                ),
                              ),
                              padding: EdgeInsets.only(
                                top: 14.h,
                                bottom: 14.h,
                                left: 24.w,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  visible ? '비공개로 전환' : '공개로 전환',
                                  style: TextStyle(
                                    color: blackBold,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => changeFolderName(
                              parentContext,
                              folders,
                              currFolder,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10.r),
                                ),
                                color: Colors.transparent,
                              ),
                              padding: EdgeInsets.only(
                                top: 14.h,
                                bottom: 14.h,
                                left: 24.w,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '폴더명 변경',
                                  style: TextStyle(
                                    color: blackBold,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                deleteFolderDialog(parentContext, currFolder),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10.r),
                                ),
                                color: Colors.transparent,
                              ),
                              padding: EdgeInsets.only(
                                top: 14.h,
                                bottom: 14.h,
                                left: 24.w,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '폴더 삭제',
                                  style: TextStyle(
                                    color: blackBold,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                            ),
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

  void changeFolderVisible(BuildContext context, Folder folder) {
    context.read<GetFoldersCubit>().transferVisible(folder).then((value) {
      Navigator.pop(context);
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
    ).then((value) {
      value = value ?? false;
      if (value) {
        Navigator.pop(context, true);
        context.read<GetFoldersCubit>().getFolders();
      }
    });
  }
}
