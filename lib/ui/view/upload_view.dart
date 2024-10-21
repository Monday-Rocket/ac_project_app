// ignore_for_file: avoid_positional_boolean_parameters

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_link_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/cubits/sign_up/button_state_cubit.dart';
import 'package:ac_project_app/enums/navigator_pop_type.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/link/upload_type.dart';
import 'package:ac_project_app/provider/upload_state_variable.dart';
import 'package:ac_project_app/ui/widget/add_folder/folder_add_title.dart';
import 'package:ac_project_app/ui/widget/add_folder/horizontal_folder_list.dart';
import 'package:ac_project_app/ui/widget/add_folder/subtitle.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/ui/widget/dialog/center_dialog.dart';
import 'package:ac_project_app/ui/widget/loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

class UploadView extends StatefulWidget {
  const UploadView({super.key, this.args});

  final Map<String, dynamic>? args;

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  final linkTextController = TextEditingController();
  final commentTextController = TextEditingController();

  final parentScrollController = ScrollController();
  final firstScrollController = ScrollController();
  final secondScrollController = ScrollController();
  ButtonState buttonState = ButtonState.disabled;
  int selectedIndex = 0;
  int? selectedFolderId;
  bool isSavedNewFolder = false;
  bool isLoading = false;

  @override
  void initState() {
    if (widget.args != null) {
      linkTextController.text = widget.args!['url'] as String;
      buttonState = ButtonState.enabled;
    }
    isNotUploadState = false;
    super.initState();
  }

  @override
  void dispose() {
    isNotUploadState = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GetFoldersCubit>(
          create: (_) => GetFoldersCubit(),
        ),
        BlocProvider<UploadLinkCubit>(
          create: (_) => UploadLinkCubit(),
        ),
      ],
      child: KeyboardDismissOnTap(
        child: KeyboardVisibilityBuilder(
          builder: (context, visible) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

            return Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.white,
              appBar: AppBar(
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: SvgPicture.asset(Assets.images.icBack),
                  color: grey900,
                  padding: EdgeInsets.only(left: 20.w, right: 8.w),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                title: Text(
                  '업로드',
                  style: TextStyle(
                    color: grey900,
                    fontWeight: FontWeight.bold,
                    fontSize: 19.sp,
                    height: (22 / 19).h,
                    letterSpacing: -0.3.w,
                  ),
                ),
              ),
              body: Stack(
                children: [
                  SingleChildScrollView(
                    reverse: visible,
                    controller: parentScrollController,
                    physics: const ClampingScrollPhysics(),
                    child: SafeArea(
                      child: Container(
                        margin: EdgeInsets.only(left: 24.w, top: 20.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSubTitle('링크'),
                            buildLinkTextField(),
                            BlocBuilder<GetFoldersCubit, FoldersState>(
                              builder: (folderContext, state) {
                                return Column(
                                  children: [
                                    if (state is FolderLoadedState)
                                      buildFolderSelectTitle(
                                        context,
                                        '폴더 선택',
                                        state.folders,
                                        callback: () {
                                          setState(() {
                                            isSavedNewFolder = true;
                                          });
                                        },
                                      ),
                                    buildFolderList(
                                      folderContext: folderContext,
                                      state: state,
                                      callback: (index, folder) => setState(() {
                                        selectedIndex = index;
                                        selectedFolderId = folder.id;
                                        isSavedNewFolder = false;
                                      }),
                                      selectedIndex: selectedIndex,
                                      isLast: isSavedNewFolder,
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: 35.h),
                            buildSubTitle('링크 코멘트'),
                            buildCommentTextField(visible),
                            SizedBox(height: 13.h),
                            buildUploadWarning(true),
                            SizedBox(
                              height: keyboardHeight.h,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    Center(
                      child: LoadingWidget(),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
              bottomSheet: buildBottomSheetButton(
                context: context,
                text: '등록완료',
                keyboardVisible: visible,
                onPressed: buttonState == ButtonState.enabled
                    ? () => completeRegister(context)
                    : null,
                buttonShadow: false,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildUploadWarning(bool visible) {
    return Container(
      margin: EdgeInsets.only(
        right: 24.w,
      ),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8.r)),
        color: grey50,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 12.w, top: 12.h, bottom: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 3.h),
              child: SvgPicture.asset(Assets.images.warningMark),
            ),
            SizedBox(width: 4.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warningMsgTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: grey600,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(
                  height: 6.h,
                ),
                SizedBox(
                  width: 280.h,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      warningMsgContent,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: grey400,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Container buildCommentTextField(bool visible) {
    return Container(
      margin: EdgeInsets.only(
        top: 14.h,
        right: 24.w,
      ),
      height: 110.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12.r)),
        color: grey100,
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            controller: secondScrollController,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 80.h,
              child: TextField(
                controller: commentTextController,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: (19.6 / 14).h,
                  color: grey600,
                  letterSpacing: -0.3.w,
                ),
                cursorColor: primary600,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                maxLength: 500,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 15.h,
                    horizontal: 16.w,
                  ),
                  hintText: '저장한 링크에 대해 간단하게 메모해보세요',
                  hintStyle: TextStyle(
                    color: grey400,
                    fontSize: 14.sp,
                    letterSpacing: -0.3,
                  ),
                  counterText: '',
                ),
                onTap: () {
                  if (visible) {
                    parentScrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                    );
                  }
                },
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(right: 14.w),
              child: Text(
                '${commentTextController.text.length}/500',
                style: TextStyle(
                  color: grey400,
                  fontSize: 14.sp,
                  letterSpacing: -0.3,
                  height: (16.7 / 14).h,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLinkTextField() {
    return BlocBuilder<UploadLinkCubit, UploadResult>(
      builder: (context, uploadResult) {
        final linkError = uploadResult.state == UploadResultState.error;
        return Column(
          children: [
            buildBodyListItem(uploadResult),
            Container(
              margin: EdgeInsets.only(
                top: 14.h,
                right: 24.w,
                bottom: 15.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: linkError ? redError2 : grey100),
                      borderRadius: BorderRadius.all(Radius.circular(12.r)),
                      color: grey100,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      controller: firstScrollController,
                      child: SizedBox(
                        height: 80.h,
                        child: TextField(
                          controller: linkTextController,
                          style: TextStyle(
                            fontSize: 14.sp,
                            height: (16.7 / 14).h,
                            color: grey600,
                            letterSpacing: -0.3.w,
                          ),
                          cursorColor: primary600,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 15.h,
                              horizontal: 16.w,
                            ),
                            hintText: '링크를 여기에 불러주세요',
                            hintStyle: TextStyle(
                              color: grey400,
                              fontSize: 14.sp,
                              letterSpacing: -0.3.w,
                            ),
                          ),
                          onChanged: (url) => setState(() {
                            if (url.isNotEmpty) {
                              buttonState = ButtonState.enabled;
                            }
                            context.read<UploadLinkCubit>().validateMetadata(url);
                          }),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Text(
                      '링크 형식으로 입력해 주세요',
                      style: TextStyle(
                        color: linkError ? redError2 : Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                        height: (14.3 / 12).h,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildBodyListItem(UploadResult result) {
    if (result.isNotValidAndSuccess()) {
      return const SizedBox.shrink();
    }
    final metadata = result.metadata!;
    return Container(
      margin: EdgeInsets.only(
        top: 18.h,
        left: 6.w,
        right: 24.w,
        bottom: 18.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 115.h,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 5.h),
              width: 130.w,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metadata.title ?? '',
                          maxLines: 1,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: blackBold,
                            overflow: TextOverflow.ellipsis,
                            height: (19 / 16).h,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 7.h),
                        Text(
                          metadata.description ?? '\n\n',
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: greyText,
                            overflow: TextOverflow.ellipsis,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: ClipRRect(
              borderRadius: BorderRadius.all(
                Radius.circular(7.r),
              ),
              child: ColoredBox(
                color: grey100,
                child: metadata.image != null && metadata.image!.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: metadata.image ?? '',
                  imageBuilder: (context, imageProvider) => Container(
                    width: 159.w,
                    height: 116.h,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) {
                    return SizedBox(
                      width: 159.w,
                      height: 116.h,
                    );
                  },
                )
                    : SizedBox(
                  width: 159.w,
                  height: 116.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void completeRegister(BuildContext context) {
    setLoading();
    context
        .read<UploadLinkCubit>()
        .completeRegister(
          linkTextController.text,
          commentTextController.text,
          selectedFolderId,
          UploadType.create,
        )
        .then((result) {
      if (result.state == UploadResultState.success) {
        showBottomToast(
          context: context,
          '링크 등록 완료',
          duration: 1000,
        );
        Navigator.pop(context, NavigatorPopType.saveLink);
      } else if (result == UploadResultState.duplicated) {
        showPopUp(
          title: '업로드 실패',
          content: '입력하신 링크는 이미 업로드한 링크에요\n링크를 다시 한번 확인해 주세요',
          parentContext: context,
          callback: () {
            Navigator.pop(context);
          },
        );
      } else if (result == UploadResultState.apiError) {
        showError(context);
      }
      setLoadingEnd();
    }).catchError((e) {
      setLoadingEnd();
    });
  }

  void setLoading() {
    setState(() {
      buttonState = ButtonState.disabled; // 중복 터치 방지
      isLoading = true;
    });
  }

  void setLoadingEnd() {
    setState(() {
      isLoading = false;
    });
  }
}
