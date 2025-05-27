import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/sign_up/button_state_cubit.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class SharedLinkSettingView extends StatefulWidget {
  const SharedLinkSettingView({super.key});

  @override
  State<SharedLinkSettingView> createState() => _SharedLinkSettingViewState();
}

class _SharedLinkSettingViewState extends State<SharedLinkSettingView> {
  bool isPrivateFolder = false;
  ButtonState buttonState = ButtonState.disabled;
  Folder folder = const Folder();
  final TextEditingController _folderNameController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = getArguments(context);
      folder = arguments['folder'] as Folder;
      isPrivateFolder = folder.visible ?? false;
      _folderNameController.text = folder.name ?? '';
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetFoldersCubit(),
        ),
        BlocProvider(
          create: (context) => ButtonStateCubit(),
        ),
      ],
      child: KeyboardDismissOnTap(
        child: KeyboardVisibilityBuilder(
          builder: (context, visibility) {
            return BlocBuilder<ButtonStateCubit, ButtonState>(
              builder: (context, state) {
                return Scaffold(
                  backgroundColor: Colors.white,
                  appBar: AppBar(
                    leading: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: SvgPicture.asset(Assets.images.icBack, width: 24.w, height: 24.w, fit: BoxFit.cover),
                      color: grey900,
                      padding: EdgeInsets.only(left: 20.w, right: 8.w),
                    ),
                    leadingWidth: 44.w,
                    toolbarHeight: 48.w,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    systemOverlayStyle: SystemUiOverlayStyle.dark,
                    title: Text(
                      '폴더설정',
                      style: TextStyle(
                        color: grey900,
                        fontWeight: FontWeight.bold,
                        fontSize: 19.sp,
                        height: 23 / 19,
                        letterSpacing: -0.3.w,
                      ),
                    ),
                  ),
                  body: Container(
                    margin: const EdgeInsets.only(left: 24, right: 24, top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '폴더이름',
                              style: _titleStyle,
                            ),
                            SizedBox(
                              width: 200,
                              height: 19,
                              child: TextField(
                                controller: _folderNameController,
                                onChanged: (value) {
                                  if (value.length > 20) {
                                    _folderNameController.text = value.substring(0, 20);
                                  }
                                  if (value.isNotEmpty) {
                                    context.read<ButtonStateCubit>().enable();
                                  } else {
                                    context.read<ButtonStateCubit>().disable();
                                  }
                                },
                                decoration: null,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16.sp,
                                  letterSpacing: 0,
                                  color: grey600,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            )
                          ],
                        ),
                        GreyDivider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '비공개 폴더',
                              style: _titleStyle,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isPrivateFolder = !isPrivateFolder;
                                });
                                context.read<ButtonStateCubit>().enable();
                              },
                              child: toggleButton(),
                            ),
                          ],
                        ),
                        GreyDivider(),
                        InkWell(
                          onTap: () {},
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '폴더 삭제',
                                style: _titleStyle,
                              ),
                              4.verticalSpace,
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  '공유 폴더 삭제 시 함께하던 멤버들도 폴더가 삭제돼요',
                                  style: TextStyle(
                                    color: grey400,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14.sp,
                                    letterSpacing: 0,
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  bottomSheet: buildBottomSheetButton(
                    context: context,
                    text: '수정완료',
                    buttonShadow: false,
                    keyboardVisible: visibility,
                    onPressed: onPressed(context, state),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> Function()? onPressed(BuildContext context, ButtonState state) {
    return state == ButtonState.enabled
        ? () async {
            final result = await context.read<GetFoldersCubit>().changeNameAndVisible(folder.copyWith(
                  name: _folderNameController.text,
                  visible: isPrivateFolder,
                ));
            if (result) {
              showBottomToast(
                context: context,
                '폴더명이 변경되었어요!',
              );
              Navigator.pop(context);
              Navigator.pop(context, true);
            } else {
              showBottomToast(
                context: context,
                '폴더명 변경에 실패했어요',
              );
            }
          }
        : null;
  }

  SvgPicture toggleButton() {
    return !isPrivateFolder
        ? SvgPicture.asset(
            Assets.images.toggleOn,
          )
        : SvgPicture.asset(
            Assets.images.toggleOff,
          );
  }

  TextStyle get _titleStyle {
    return TextStyle(
      color: grey800,
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
  }

  Padding GreyDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: greyTab),
    );
  }
}
