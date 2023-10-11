import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/ui/widget/add_folder/folder_add_title.dart';
import 'package:ac_project_app/ui/widget/add_folder/horizontal_folder_list.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<bool?> moveToMyFolderDialog(BuildContext parentContext) {
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
                      top: 32.h,
                      bottom: 30.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTitle(context, '폴더 선택', titleLeft: 24.w),
                        Container(
                          margin: EdgeInsets.only(top: 17.h, bottom: 20.h),
                          child: Divider(
                            height: 1.h,
                            thickness: 1.h,
                            color: grey100,
                          ),
                        ),
                        if (state is FolderLoadedState)
                          Container(
                            margin: EdgeInsets.only(left: 24.w),
                            child: buildFolderSelectTitle(
                              foldersContext,
                              '내 폴더',
                              state.folders,
                            ),
                          ),
                        Container(
                          margin: EdgeInsets.only(left: 24.w),
                          child: buildFolderList(
                            folderContext: foldersContext,
                            state: state,
                            callback: (_, folderId) {},
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
