// ignore_for_file: avoid_positional_boolean_parameters

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/links/detail_edit_cubit.dart';
import 'package:ac_project_app/cubits/links/edit_state.dart';
import 'package:ac_project_app/cubits/links/upload_link_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/comment_temp_data_provider.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
import 'package:ac_project_app/ui/widget/dialog/center_dialog.dart';
import 'package:ac_project_app/ui/widget/link_hero.dart';
import 'package:ac_project_app/ui/widget/user/user_info.dart';
import 'package:ac_project_app/util/date_utils.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkDetailView extends StatefulWidget {
  const LinkDetailView({super.key});

  @override
  State<LinkDetailView> createState() => _LinkDetailViewState();
}

class _LinkDetailViewState extends State<LinkDetailView> {

  final scrollController = ScrollController();
  late Link? globalLink;
  late bool? isMine;
  late bool linkVisible;
  
  @override
  Widget build(BuildContext context) {
    final args = getArguments(context);
    globalLink = args['link'] as Link;
    isMine = args['isMine'] as bool?;
    linkVisible = args['visible'] as bool? ?? true;

    final profileState = context.watch<GetProfileInfoCubit>().state;
    var isMyLink = false;
    if (profileState is ProfileLoadedState) {
      isMyLink = profileState.profile.id == globalLink!.user?.id;
    }
    if (isMine ?? false) {
      isMyLink = true;
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DetailEditCubit(globalLink)),
        BlocProvider(create: (_) => GetUserFoldersCubit()),
        BlocProvider(create: (_) => UploadLinkCubit()),
      ],
      child: KeyboardDismissOnTap(
        child: KeyboardVisibilityBuilder(
          builder: (context, visible) {
            return BlocBuilder<DetailEditCubit, EditState>(
              builder: (cubitContext, editState) {
                final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
                if (editState.type == EditStateType.edit) {
                  return PopScope(
                    onPopInvoked: (bool didPop) {
                      Log.d('onPopInvoked edit: $didPop');
                      if (didPop) return;
                      goBackPage(editState, context, globalLink!.id);
                    },
                    child: buildMainScreen(
                      editState,
                      context,
                      isMyLink,
                      globalLink!,
                      scrollController,
                      cubitContext,
                      keyboardHeight,
                      visible,
                      linkVisible,
                    ),
                  );
                } else {
                  return PopScope(
                    onPopInvoked: (bool didPop) {
                      Log.d('onPopInvoked ${editState.type}: $didPop');
                      if (didPop) return;
                      changePreviousViewIfEdited(editState, context);
                    },
                    canPop: false,
                    child: buildMainScreen(
                      editState,
                      context,
                      isMyLink,
                      editState.link ?? globalLink!,
                      scrollController,
                      cubitContext,
                      keyboardHeight,
                      visible,
                      linkVisible,
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  void changePreviousViewIfEdited(EditState editState, BuildContext context) {
    Log.d('changePreviousViewIfEdited: ${editState.type}');
    if (editState.type == EditStateType.editedView) {
      Navigator.pop(context, 'changed');
    } else {
      Navigator.pop(context);
    }
  }

  Scaffold buildMainScreen(
    EditState editState,
    BuildContext context,
    bool isMyLink,
    Link link,
    ScrollController scrollController,
    BuildContext cubitContext,
    double keyboardHeight,
    bool visible,
    bool linkVisible,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            goBackPage(editState, context, link.id);
          },
          icon: SvgPicture.asset(Assets.images.icBack),
          padding: EdgeInsets.only(left: 20.w, right: 8.w),
        ),
        actions: [
          InkWell(
            onTap: () => isMyLink
                ? showMyLinkOptionsDialog(
                    link,
                    context,
                    linkVisible: linkVisible,
                  )
                : showLinkOptionsDialog(
                    link,
                    context,
                    callback: () => Navigator.pop(context),
                  ),
            child: Container(
              margin: EdgeInsets.only(right: 24.w),
              child: SvgPicture.asset(
                Assets.images.more,
                width: 25.w,
                height: 25.h,
              ),
            ),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: buildBody(
        scrollController,
        editState,
        link,
        cubitContext,
        isMyLink,
        keyboardHeight,
      ),
      bottomSheet: Builder(
        builder: (_) {
          if (editState.type == EditStateType.edit) {
            return buildBottomSheetButton(
              context: context,
              text: '확인',
              keyboardVisible: visible,
              onPressed: () {
                cubitContext.read<DetailEditCubit>().saveComment(link).then((newLink) {
                  cubitContext.read<DetailEditCubit>().toggleEdit(newLink);
                  setState(() {
                    globalLink = newLink;
                  });
                });
              },
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  void goBackPage(EditState editState, BuildContext context, int? linkId) {
    if (editState.type == EditStateType.edit) {
      showWaitDialog(
        context,
        callback: () {
          final value = context.read<DetailEditCubit>().textController.text;
          saveKeyValue(linkId!.toString(), value).then((value) {
            Navigator.pop(context); // 창 닫기
            Navigator.pop(context); // 뒤로 가기
          });
        },
      );
    } else if (editState.type == EditStateType.editedView) {
      Navigator.pop(context, 'changed');
    } else {
      Navigator.pop(context);
    }
  }

  void showWaitDialog(
    BuildContext context, {
    required void Function() callback,
  }) {
    showPopUp(
      title: '작성을 중단하시겠어요?',
      content: '작성 중인 내용은 임시저장돼요',
      parentContext: context,
      callback: callback,
    );
  }

  Widget buildBody(
    ScrollController scrollController,
    EditState state,
    Link link,
    BuildContext cubitContext,
    bool isMyLink,
    double keyboardHeight,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      reverse: state.type == EditStateType.edit,
      child: Container(
        margin: EdgeInsets.only(left: 24.w, right: 24.w, top: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<GetProfileInfoCubit, ProfileState>(
              builder: (context, state) {
                return UserInfoWidget(
                  context: cubitContext,
                  link: link,
                  jobVisible: false,
                );
              },
            ),
            SizedBox(height: 20.h),
            InkWell(
              onTap: () async {
                await launchUrl(
                  Uri.parse(link.url ?? ''),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0F444C94),
                      spreadRadius: 10.r,
                      blurRadius: 10.r,
                      offset: Offset(12.w, 15.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinkHero(
                      tag: 'linkImage${link.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10.r),
                          topRight: Radius.circular(10.r),
                        ),
                        child: Image.network(
                          link.image ?? '',
                          fit: BoxFit.cover,
                          width: MediaQuery.of(cubitContext).size.width - 48.w,
                          height: 193.h,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10.r),
                                  topRight: Radius.circular(10.r),
                                ),
                              ),
                              width:
                                  MediaQuery.of(cubitContext).size.width - 48.w,
                              height: 10.h,
                            );
                          },
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10.r),
                          bottomRight: Radius.circular(10.r),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(19.w, 23.h, 47.w, 33.h),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinkHero(
                                tag: 'linkTitle${link.id}',
                                child: Text(
                                  link.title ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17.sp,
                                    color: blackBold,
                                    letterSpacing: -0.2.w,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              LinkHero(
                                tag: 'linkUrl${link.id}',
                                child: Container(
                                  margin: EdgeInsets.only(top: 7.h),
                                  child: Text(
                                    link.url ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFFC0C2C4),
                                      letterSpacing: -0.1.w,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 44.h,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Text(
                    getMonthDayYear(link.time ?? ''),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: grey400,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Visibility(
                  visible: isMyLink,
                  child: GestureDetector(
                    onTap: () {
                      toggleEditorWithDialog(state, cubitContext, link);
                    },
                    onDoubleTap: () {
                      toggleEditorWithDialog(state, cubitContext, link);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: SvgPicture.asset(
                        Assets.images.icWriteComment,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.only(bottom: 22.h),
              color: const Color(0xffecedee),
              height: 1.h,
              width: double.infinity,
            ),
            Builder(
              builder: (_) {
                if (state.type == EditStateType.view || state.type == EditStateType.editedView) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          minHeight: 240.h,
                        ),
                        child: Text(
                          link.describe ?? '',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: e6Grey700,
                            letterSpacing: -0.1.w,
                            height: (26 / 16).h,
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 22.h, bottom: 47.h),
                        color: const Color(0xffecedee),
                        height: 1.h,
                        width: double.infinity,
                      ),
                    ],
                  );
                } else {
                  return Container(
                    margin: EdgeInsets.only(bottom: 80.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12.r)),
                      color: grey100,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: 120.h,
                        ),
                        child: TextField(
                          controller: cubitContext
                              .read<DetailEditCubit>()
                              .textController,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: grey700,
                            height: (19.6 / 14).h,
                            letterSpacing: -0.1.w,
                          ),
                          cursorColor: primary600,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          autofocus: true,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.all(17.r),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: keyboardHeight),
          ],
        ),
      ),
    );
  }

  void toggleEditorWithDialog(
    EditState state,
    BuildContext cubitContext,
    Link link,
  ) {
    final linkId = link.id;
    if (state.type == EditStateType.edit) {
      showWaitDialog(
        cubitContext,
        callback: () {
          final value =
              cubitContext.read<DetailEditCubit>().textController.text;
          Log.i('value: $value');
          saveKeyValue(linkId!.toString(), value).then(
            (_) => toggleEditor(cubitContext)
                .then((_) => Navigator.pop(cubitContext)),
          );
        },
      );
    } else {
      getValueFromKey(linkId!.toString()).then((temp) {
        if (temp.isNotEmpty) {
          cubitContext.read<DetailEditCubit>().textController.text = temp;
        } else {
          cubitContext
              .read<DetailEditCubit>()
              .textController
              .text = link.describe ?? '';
        }
        toggleEditor(cubitContext);
      });
    }
  }

  Future<void> toggleEditor(BuildContext cubitContext) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(
      const Duration(milliseconds: 200),
      cubitContext.read<DetailEditCubit>().toggle,
    );
  }
}
