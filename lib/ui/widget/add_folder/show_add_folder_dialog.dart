import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folder_name_cubit.dart';
import 'package:ac_project_app/cubits/common/button_state_cubit.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<bool?> showAddFolderDialog(
  BuildContext parentContext, {
  required List<Folder> folders,
  void Function(BuildContext context, List<Folder> folders, int index)? moveToMyLinksView,
  void Function()? callback,
  bool? hasNotUnclassified,
}) async {
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<bool>(
    backgroundColor: Colors.transparent,
    context: parentContext,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ButtonStateCubit()),
          BlocProvider(create: (_) => FolderNameCubit()),
        ],
        child: Wrap(
          children: [
            KeyboardDismissOnTap(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.w),
                    topRight: Radius.circular(20.w),
                  ),
                ),
                child: _buildDialogBody(
                  context,
                  parentContext,
                  moveToMyLinksView,
                  callback,
                  hasNotUnclassified,
                  formKey,
                  folders,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Padding _buildDialogBody(
  BuildContext context,
  BuildContext parentContext,
  void Function(BuildContext context, List<Folder> folders, int index)? moveToMyLinksView,
  void Function()? callback,
  bool? hasNotUnclassified,
  GlobalKey<FormState> formKey,
  List<Folder> folders,
) {
  return Padding(
    padding: EdgeInsets.only(
      top: 30.w,
      left: 24.w,
      right: 24.w,
      bottom: MediaQuery.of(context).viewInsets.bottom + 16.w,
    ),
    child: Builder(
      builder: (context) => Column(
          children: [
            Stack(
              children: [
                Center(
                  child: const Text('새로운 폴더').bold().fontSize(20.sp),
                ),
                BlocBuilder<ButtonStateCubit, ButtonState>(
                  builder: (context, state) {
                    return Container(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () => saveEmptyFolder(
                          context,
                          parentContext,
                          context.read<FolderNameCubit>().state,
                          moveToMyLinksView: moveToMyLinksView,
                          callback: callback,
                          hasNotUnclassified: hasNotUnclassified,
                        ),
                        child: Text(
                          '완료',
                          style: TextStyle(
                            color: state == ButtonState.disabled ? grey300 : grey800,
                            fontWeight: FontWeight.w500,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  margin: EdgeInsets.only(top: 60.w),
                  child: Form(
                    key: formKey,
                    child: TextFormField(
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: grey800,
                      ),
                      cursorColor: primary600,
                      decoration: InputDecoration(
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: primary800,
                            width: 2.w,
                          ),
                        ),
                        errorStyle: const TextStyle(
                          color: redError,
                        ),
                        focusedErrorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: redError,
                            width: 2.w,
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: greyTab,
                            width: 2.w,
                          ),
                        ),
                        suffix: context.read<FolderNameCubit>().state.isEmpty
                            ? const SizedBox.shrink()
                            : InkWell(
                                onTap: () {
                                  context.read<FolderNameCubit>().update('');
                                  context.read<ButtonStateCubit>().disable();
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 19.w,
                                ),
                              ),
                        hintStyle: TextStyle(
                          color: grey400,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: '새로운 폴더 이름',
                      ),
                      validator: (value) {
                        if (Folder.containsNameFromFolderList(folders, value)) {
                          return '이미 사용하고 있는 폴더명이예요. 새로운 폴더명을 입력해주세요.';
                        }
                        if (value != null && value.length > 20) {
                          return '20자 이하로 입력해주세요.';
                        }

                        return null;
                      },
                      onSaved: (String? value) {
                        Log.i('onSaved $value');
                      },
                      onChanged: (String? value) {
                        final validate = formKey.currentState?.validate();
                        if (validate != true) {
                          context.read<ButtonStateCubit>().disable();
                        } else {
                          context.read<ButtonStateCubit>().enable();
                          context.read<FolderNameCubit>().update(value!);
                        }
                      },
                      onFieldSubmitted: (value) {
                        saveEmptyFolder(
                          context,
                          parentContext,
                          value,
                          moveToMyLinksView: moveToMyLinksView,
                          callback: callback,
                          hasNotUnclassified: hasNotUnclassified,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            BlocBuilder<ButtonStateCubit, ButtonState>(
              builder: (context, state) {
                return Container(
                  margin: EdgeInsets.only(
                    top: 40.w,
                    bottom: Platform.isAndroid ? MediaQuery.of(context).padding.bottom : 16.w,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(55.w),
                      backgroundColor: state == ButtonState.disabled ? secondary : primary600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: state == ButtonState.enabled
                        ? () => saveEmptyFolder(
                              context,
                              parentContext,
                              context.read<FolderNameCubit>().state,
                              moveToMyLinksView: moveToMyLinksView,
                              callback: callback,
                              hasNotUnclassified: hasNotUnclassified,
                            )
                        : null,
                    child: Text(
                      '폴더 생성하기',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textWidthBasis: TextWidthBasis.parent,
                    ),
                  ),
                );
              },
            ),
          ],
      ),
    ),
  );
}
