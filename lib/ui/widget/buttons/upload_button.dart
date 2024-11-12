import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/enums/navigator_pop_type.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget FloatingUploadButton(
  BuildContext context, {
  void Function(VoidCallback fn)? setState,
  void Function()? callback,
}) {
  return Positioned(
    bottom: 20.w,
    right: 20.w,
    child: GestureDetector(
      onTap: () {
        pushUploadView(context, setState: setState, callback: callback);
      },
      child: Container(
        width: 94.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: primary600,
          borderRadius: BorderRadius.circular(40.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(6, 6),
              blurRadius: 40.r,
            ),
          ],
        ),
        child: Row(
          children: [
            12.horizontalSpace,
            SvgPicture.asset(
              Assets.images.uploadPlus,
              width: 20.w,
              height: 20.w,
              fit: BoxFit.cover,
            ),
            2.horizontalSpace,
            Text(
              '업로드',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void pushUploadView(
  BuildContext context, {
  void Function(VoidCallback fn)? setState,
  void Function()? callback,
}) {
  Navigator.pushNamed(context, Routes.upload).then(
    (value) => setState != null
        ? (
            () {
              showSaved(value, context, callback);
            },
          )
        : showSaved(value, context, callback),
  );
}

void showSaved(Object? value, BuildContext context, void Function()? callback) {
  if (NavigatorPopType.saveLink == value) {
    showBottomToast(
      context: context,
      '링크가 저장되었어요!',
    );
    context.read<GetFoldersCubit>().getFolders();
    callback?.call();
  }
}
