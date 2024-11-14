import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/ui/widget/add_folder/show_add_folder_dialog.dart';
import 'package:ac_project_app/ui/widget/add_folder/subtitle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

Container buildFolderSelectTitle(
  BuildContext context,
  String text,
  List<Folder> folders, {
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
          onTap: () => showAddFolderDialog(
            context,
            hasNotUnclassified: true,
            folders: folders,
            callback: callback,
          ),
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
