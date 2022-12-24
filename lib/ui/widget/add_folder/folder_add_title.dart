import 'package:ac_project_app/ui/widget/add_folder/show_add_folder_dialog.dart';
import 'package:ac_project_app/ui/widget/add_folder/subtitle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Container buildFolderSelectTitle(BuildContext context, String text) {
  return Container(
    margin: const EdgeInsets.only(
      right: 16,
      bottom: 3,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildSubTitle(text),
        InkWell(
          onTap: () => showAddFolderDialog(
            context,
            isFromUpload: true,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SvgPicture.asset(
              'assets/images/btn_add.svg',
            ),
          ),
        ),
      ],
    ),
  );
}