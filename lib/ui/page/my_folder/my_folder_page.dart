// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/local_folders_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/add_folder/show_add_folder_dialog.dart';
import 'package:ac_project_app/ui/widget/buttons/upload_button.dart';
import 'package:ac_project_app/ui/widget/custom_reorderable_list_view.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
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

class _MyFolderPageState extends State<MyFolderPage> with WidgetsBindingObserver {
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
    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
    if (state == AppLifecycleState.resumed || state == AppLifecycleState.detached) {
      Future.delayed(const Duration(milliseconds: 300), () {
        context.read<LocalFoldersCubit>().getFolders().then((value) {
          setState(() {});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: BlocBuilder<LocalFoldersCubit, FoldersState>(
        builder: (getFolderContext, folderState) {
          return Stack(
            children: [
              Assets.images.myFolderBack.image(
                width: width,
                fit: BoxFit.fill,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProfileView(folderState),
                  SearchView(context, folderState),
                  FolderListView(folderState),
                ],
              ),
              FloatingUploadButton(context, callback: () {
                getFolderContext.read<LocalFoldersCubit>().getFolders();
              }),
            ],
          );
        },
      ),
    );
  }

  Builder FolderListView(FoldersState folderState) {
    return Builder(
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
    );
  }

  Container SearchView(BuildContext context, FoldersState folderState) {
    return Container(
      margin: EdgeInsetsDirectional.only(
        top: 50.w,
        start: 20,
        end: 20,
        bottom: 6.w,
      ),
      child: Row(
        children: [
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: grey100,
                borderRadius: BorderRadius.all(Radius.circular(7.w)),
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
                  context.read<LocalFoldersCubit>().filter(value);
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
                padding: EdgeInsets.all(6.w),
                child: SvgPicture.asset(
                  Assets.images.btnAdd,
                ),
              ),
            ),
        ],
      ),
    );
  }

  BlocBuilder<GetProfileInfoCubit, ProfileState> ProfileView(FoldersState folderState) {
    var linksText = '';
    var addedLinksCount = 0;
    if (folderState is FolderLoadedState) {
      linksText = folderState.totalLinksText;
      addedLinksCount = folderState.addedLinksCount;
    }

    return BlocBuilder<GetProfileInfoCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoadedState) {
          final profile = state.profile;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 105.w,
                height: 105.w,
                margin: EdgeInsetsDirectional.only(
                  top: 90.w,
                  bottom: 24.w,
                ),
                child: Image.asset(
                  ProfileImage.makeImagePath(
                    profile.profileImage,
                  ),
                  width: 96.w,
                  height: 96.w,
                  fit: BoxFit.cover,
                ),
              ),
              Text(
                profile.nickname,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28.sp,
                  color: const Color(0xff0e0e0e),
                ),
              ),
              10.verticalSpace,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '총 링크',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                      color: grey600,
                    ),
                  ),
                  6.horizontalSpace,
                  Text(
                    linksText,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                      color: grey800,
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 9.w,
                    color: greyD9,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  Text(
                    '추가된 링크',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                      color: grey600,
                    ),
                  ),
                  6.horizontalSpace,
                  Text(
                    addCommasFrom(addedLinksCount),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                      color: grey800,
                    ),
                  ),
                ],
              )
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
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
        'selectedFolder': folders[index],
        'tabIndex': index,
      },
    ).then((_) {
      context.read<LocalFoldersCubit>().getFolders();
    });
  }

  Widget buildListView(List<Folder> folders, BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        child: RefreshIndicator(
          onRefresh: () async => context.read<LocalFoldersCubit>().getFolders(),
          color: primary600,
          child: CustomReorderableListView.separated(
            shrinkWrap: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: folders.length,
            separatorBuilder: (ctx, index) {
              return Divider(
                thickness: 1.w,
                height: 1.w,
                color: greyTab,
              );
            },
            itemBuilder: (ctx, index) {
              return FolderListItem(folders, index, context);
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

  ListTile FolderListItem(List<Folder> folders, int index, BuildContext context) {
    final folder = folders[index];
    final isAdmin = folder.isAdmin ?? false;
    final isSharedFolder = folder.shared ?? false;
    final visible = folder.visible ?? true;
    final isNotClassified = folder.name == '미분류';
    final isLastFolder = index == folders.length - 1;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      key: Key('$index'),
      title: InkWell(
        onTap: () {
          moveToMyLinksView(context, folders, index);
        },
        child: Container(
          margin: EdgeInsets.only(top: 20, bottom: isLastFolder ? 40 : 20, left: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 69.w,
                    height: 63.w,
                    margin: EdgeInsets.only(right: 30.w),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20.w),
                          ),
                          child: ColoredBox(
                            color: grey100,
                            child: FolderThumbnail(folder),
                          ),
                        ),
                        if (!visible)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 3.w),
                              child: Assets.images.icLockWebp.image(width: 24.w, height: 24.w, fit: BoxFit.cover),
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
                      SharedCountText(isSharedFolder, folder.membersCount),
                      SizedBox(
                        width: 120.w,
                        child: Text(
                          folder.name!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: blackBold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 6.w,
                      ),
                      Text(
                        '링크 ${addCommasFrom(folder.links)}개',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: greyText,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isNotClassified)
                const SizedBox.shrink()
              else
                InkWell(
                  onTap: () {
                    if (isSharedFolder) {
                      showSharedFolderOptionsDialogFromFolders(context, folder, isAdmin: isAdmin, callback: () {
                        Navigator.pop(context);
                        context.read<LocalFoldersCubit>().getFolders();
                      });
                    } else {
                      showFolderOptionsDialog(folders, folder, context);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: SvgPicture.asset(Assets.images.more),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget FolderThumbnail(Folder folder) {
    if (folder.shared ?? false) {
      return emptyFolderView(folder.shared);
    }

    return folder.thumbnail != null && (folder.thumbnail?.isNotEmpty ?? false)
        ? Image.network(
            folder.thumbnail!,
            width: 63.w,
            height: 63.w,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => emptyFolderView(folder.shared),
          )
        : emptyFolderView(folder.shared);
  }

  Container emptyFolderView(bool? shared) {
    var color = const Color(0xFFA07EFF);
    if (shared ?? false) {
      color = const Color(0xFF7EA5FF);
    }
    return Container(
      width: 63.w,
      height: 63.w,
      color: primary100,
      child: Center(
        child: SvgPicture.asset(
          Assets.images.folder,
          // color: color,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          width: 24.w,
          height: 24.w,
        ),
      ),
    );
  }

  Widget SharedCountText(bool isSharedFolder, int? membersCount) {
    if (!isSharedFolder || membersCount == null || membersCount <= 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      margin: EdgeInsets.only(bottom: 4.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$membersCount명 참여중',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF536DFE),
        ),
      ),
    );
  }
}
