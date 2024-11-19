import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_link_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/upload_type.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/add_folder/folder_add_title.dart';
import 'package:ac_project_app/ui/widget/add_folder/horizontal_folder_list.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
import 'package:ac_project_app/util/navigator_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<bool?> moveToMyFolderDialog(BuildContext parentContext, Link link) {
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
                      top: 32.w,
                      bottom: 30.w,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTitle(context, '폴더 선택', titleLeft: 24.w),
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
                              '내 폴더',
                              state.folders,
                            ),
                          ),
                        Container(
                          margin: EdgeInsets.only(left: 24.w),
                          child: buildFolderList(
                            folderContext: foldersContext,
                            state: state,
                            callback: (_, folder) {
                              onSelectFolder(
                                parentContext,
                                link,
                                folder,
                                context,
                              );
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

void onSelectFolder(
  BuildContext parentContext,
  Link link,
  Folder folder,
  BuildContext context,
) {
  popIfCan(parentContext);
  popIfCan(context);
  parentContext
      .read<UploadLinkCubit>()
      .completeRegister(
        link.url ?? '',
        link.describe ?? '',
        folder.id,
        UploadType.bring,
      )
      .then((result) {
    if (result.state == UploadResultState.success) {
      showBottomToast(
        "링크가 '${_getFolderName(folder.name ?? '')}' 폴더에 담겼어요!",
        context: parentContext,
        actionTitle: '이동하기',
        callback: () {
          Navigator.pushNamed(
            parentContext,
            Routes.linkDetail,
            arguments: {
              'link': link,
              'isMine': true,
              'visible': folder.visible,
            },
          );
        },
      );
    }
  });
}

// if folderName length is over 6, show only 4 characters and add '...'
String _getFolderName(String folderName) {
  if (folderName.length > 6) {
    return '${folderName.substring(0, 6)}...';
  } else {
    return folderName;
  }
}
