import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget buildFolderList({
  void Function(int index, Folder folder)? callback,
  int? selectedIndex,
  required BuildContext folderContext,
  required FoldersState state,
  bool? isLast,
}) {
  final scrollController = ScrollController();
  if (state is FolderLoadedState) {
    final folders = state.folders;

    void gotoLastIndex() {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );

      callback?.call(folders.length - 1, folders.last);
    }

    if (isLast ?? false) Future.microtask(gotoLastIndex);
    return Container(
      constraints: BoxConstraints(
        minHeight: 115.h,
        maxHeight: 130.h,
      ),
      child: ListView.builder(
        controller: scrollController,
        itemCount: folders.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final folder = folders[index];
          final rightPadding = index != folders.length - 1 ? 12 : 24;
          final visible = folder.visible ?? false;
          return GestureDetector(
            onTap: () {
              callback?.call(index, folder);
            },
            child: Container(
              margin: EdgeInsets.only(
                right: rightPadding.toDouble().w,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 95.w,
                        height: 95.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(32.r)),
                          color: grey100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(32.r),
                          ),
                          child: ColoredBox(
                            color: grey100,
                            child: folder.thumbnail != null &&
                                    (folder.thumbnail?.isNotEmpty ?? false)
                                ? Image.network(
                                    folder.thumbnail!,
                                    width: 95.w,
                                    height: 95.h,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        emptyFolderView(),
                                  )
                                : emptyFolderView(),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: selectedIndex == index,
                        child: Container(
                          width: 95.w,
                          height: 95.h,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.circular(32.r)),
                            color: secondary400,
                          ),
                        ),
                      ),
                      if (!visible)
                        SizedBox(
                          width: 95.w,
                          height: 95.h,
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 3.h),
                              child: Assets.images.icLockPng.image(),
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    folder.name ?? '',
                    style: TextStyle(
                      color: grey700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                      letterSpacing: -0.3.w,
                      height: (14.3 / 12).h,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  } else {
    return SizedBox(height: 115.h);
  }
}

Container emptyFolderView() {
  return Container(
    width: 95.w,
    height: 95.h,
    color: primary100,
    child: Center(
      child: SvgPicture.asset(
        Assets.images.folder,
        width: 36.w,
        height: 36.h,
      ),
    ),
  );
}
