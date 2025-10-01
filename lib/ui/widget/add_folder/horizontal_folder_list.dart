import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/shared_profiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget buildFolderList({
  required BuildContext folderContext,
  required FoldersState state,
  void Function(int index, Folder folder)? callback,
  int? selectedIndex,
  bool? isLast,
}) {
  final scrollController = ScrollController();
  if (state is FolderLoadedState) {
    final folders = state.folders;
    Log.i('folder length: ${folders.length}');

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
        minHeight: 115.w,
        maxHeight: 130.w,
      ),
      child: ListView.builder(
        controller: scrollController,
        itemCount: folders.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          return FolderItem(i, folders, callback, selectedIndex);
        },
      ),
    );
  } else {
    return SizedBox(height: 115.w);
  }
}

GestureDetector FolderItem(int i, List<Folder> folders, void Function(int index, Folder folder)? callback, int? selectedIndex) {
  final folder = folders[i];
  final rightPadding = i != folders.length - 1 ? 12 : 24;
  final visible = folder.visible ?? false;
  return GestureDetector(
    onTap: () {
      callback?.call(i, folder);
    },
    onDoubleTap: () {},
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
                height: 95.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(32.w)),
                  color: grey100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(
                    Radius.circular(32.w),
                  ),
                  child: ColoredBox(
                    color: grey100,
                    child: folder.thumbnail != null && (folder.thumbnail?.isNotEmpty ?? false)
                        ? Image.network(
                            folder.thumbnail!,
                            width: 95.w,
                            height: 95.w,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => emptyFolderView(),
                          )
                        : emptyFolderView(),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ParticipantsProfile(folder.membersCount ?? 0, scale: 0.75, fontSize: 8),
                ),
              ),
              Visibility(
                visible: selectedIndex == i,
                child: Container(
                  width: 95.w,
                  height: 95.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(32.w)),
                    color: secondary400,
                  ),
                ),
              ),
              if (!visible)
                SizedBox(
                  width: 95.w,
                  height: 95.w,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 3.w),
                      child: Assets.images.icLockWebp.image(),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
          SizedBox(height: 6.w),
          SizedBox(
            width: 95.w,
            child: Text(
              folder.name ?? '',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: grey700,
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
                letterSpacing: -0.3.w,
                height: 14.3 / 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget UnclassifiedItem(int? selectedIndex, void Function() callback) {
  return GestureDetector(
    onTap: () {
      callback.call();
    },
    onDoubleTap: () {},
    child: Column(
      children: [
        Stack(
          children: [
            Container(
              width: 95.w,
              height: 95.w,
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(32.w)),
                color: grey100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(32.w),
                ),
                child: ColoredBox(
                  color: grey100,
                  child: emptyFolderView(),
                ),
              ),
            ),
            Visibility(
              visible: selectedIndex == 0,
              child: Container(
                width: 95.w,
                height: 95.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(32.w)),
                  color: secondary400,
                ),
              ),
            ),
            SizedBox(
              width: 95.w,
              height: 95.w,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 3.w),
                  child: Assets.images.icLockWebp.image(),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.w),
        SizedBox(
          width: 95.w,
          child: Text(
            '미분류',
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: grey700,
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
              letterSpacing: -0.3.w,
              height: 14.3 / 12,
            ),
          ),
        ),
      ],
    ),
  );
}

Container emptyFolderView() {
  return Container(
    width: 95.w,
    height: 95.w,
    color: primary100,
    child: Center(
      child: SvgPicture.asset(
        Assets.images.folder,
        width: 36.w,
        height: 36.w,
      ),
    ),
  );
}
