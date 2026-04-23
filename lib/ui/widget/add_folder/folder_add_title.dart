import 'package:ac_project_app/cubits/folders/local_folders_cubit.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/ui/widget/add_folder/subtitle.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/folder/show_create_folder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

Container buildFolderSelectTitle(
  BuildContext context,
  String text,
  List<Folder> folders, {
  void Function(BuildContext context, List<Folder> folders, int index)? moveToMyLinksView,
  void Function()? callback,
}) {
  return Container(
    margin: EdgeInsets.only(
      right: 16.w,
      bottom: 3.w,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      verticalDirection: VerticalDirection.up,
      children: [
        buildSubTitle(text),
        InkWell(
          onTap: () async {
            final newId = await showCreateFolderSheet(
              context,
              allowParentPick: false,
            );
            if (newId == null || !context.mounted) return;
            await context.read<LocalFoldersCubit>().getFoldersWithoutUnclassified();
            if (!context.mounted) return;
            final updatedFolders = context.read<LocalFoldersCubit>().folders;
            moveToMyLinksView?.call(context, updatedFolders, updatedFolders.length - 1);
            callback?.call();
            if (context.mounted) {
              showBottomToast(context: context, '새로운 폴더가 생성되었어요!');
            }
          },
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: SvgPicture.asset(
              Assets.images.btnAdd,
            ),
          ),
        ),
      ],
    ),
  );
}
