import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget buildFolderList({
  void Function(int index, int folderId)? callback,
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

      callback?.call(folders.length - 1, folders.last.id!);
    }

    if (isLast ?? false) Future.microtask(gotoLastIndex);
    return Container(
      constraints: const BoxConstraints(
        minHeight: 115,
        maxHeight: 130,
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
              callback?.call(index, folder.id!);
            },
            child: Container(
              margin: EdgeInsets.only(
                right: rightPadding.toDouble(),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 95,
                        height: 95,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(32)),
                          color: grey100,
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(32),
                          ),
                          child: ColoredBox(
                            color: grey100,
                            child: folder.thumbnail != null &&
                                    (folder.thumbnail?.isNotEmpty ?? false)
                                ? Image.network(
                                    folder.thumbnail!,
                                    width: 95,
                                    height: 95,
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
                          width: 95,
                          height: 95,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(32)),
                            color: secondary400,
                          ),
                        ),
                      ),
                      if (!visible)
                        SizedBox(
                          width: 95,
                          height: 95,
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Assets.images.icLockPng.image(),
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    folder.name ?? '',
                    style: const TextStyle(
                      color: grey700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      letterSpacing: -0.3,
                      height: 14.3 / 12,
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
    return const SizedBox(height: 115);
  }
}

Container emptyFolderView() {
  return Container(
    width: 95,
    height: 95,
    color: primary100,
    child: Center(
      child: SvgPicture.asset(
        Assets.images.folder,
        width: 36,
        height: 36,
      ),
    ),
  );
}
