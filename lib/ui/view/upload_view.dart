// ignore_for_file: avoid_positional_boolean_parameters

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/consts.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/home_view_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_link_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/cubits/sign_up/button_state_cubit.dart';
import 'package:ac_project_app/ui/widget/add_folder/folder_add_title.dart';
import 'package:ac_project_app/ui/widget/add_folder/horizontal_folder_list.dart';
import 'package:ac_project_app/ui/widget/add_folder/subtitle.dart';
import 'package:ac_project_app/ui/widget/buttons/bottom_sheet_button.dart';
import 'package:ac_project_app/ui/widget/dialog.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UploadView extends StatefulWidget {
  const UploadView({super.key});

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
  int selectedIndex = -1;
  int? selectedFolderId;
  bool isSavedNewFolder = false;

  @override
  Widget build(BuildContext context) {
    final args = getArguments(context);
    final url = args['url'] as String? ?? '';
    if (url.isNotEmpty) {
      linkTextController.text = url;
    }
    final isCopied = args['isCopied'] as bool? ?? false;
    if (isCopied) {
      buttonState = isCopied ? ButtonState.enabled : ButtonState.disabled;
    }
    final height = MediaQuery.of(context).size.height;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => HomeViewCubit((args['index'] as int?) ?? 0),
        ),
        BlocProvider<GetFoldersCubit>(
          create: (_) => GetFoldersCubit(excludeUnclassified: true),
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
                  icon: SvgPicture.asset('assets/images/ic_back.svg'),
                  color: grey900,
                  padding: const EdgeInsets.only(left: 20, right: 8),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                title: const Text(
                  '업로드',
                  style: TextStyle(
                    color: grey900,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    height: 22 / 19,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              body: SingleChildScrollView(
                reverse: visible,
                controller: parentScrollController,
                physics: const ClampingScrollPhysics(),
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.only(left: 24, top: 20),
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
                                  callback: (index, folderId) => setState(() {
                                    selectedIndex = index;
                                    selectedFolderId = folderId;
                                    isSavedNewFolder = false;
                                  }),
                                  selectedIndex: selectedIndex,
                                  isLast: isSavedNewFolder,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 35),
                        buildSubTitle('링크 코멘트'),
                        buildCommentTextField(visible, height),
                        const SizedBox(height: 13),
                        buildUploadWarning(true),
                        SizedBox(
                          height: keyboardHeight,
                        ),
                      ],
                    ),
                  ),
                ),
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
      margin: const EdgeInsets.only(
        right: 24,
      ),
      height: 78,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color: grey50,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset('assets/images/warning_mark.svg'),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  warningMsgTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: grey600,
                    fontSize: 11,
                  ),
                ),
                SizedBox(
                  height: 6,
                ),
                Text(
                  warningMsgContent,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: grey400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Container buildCommentTextField(bool visible, double height) {
    return Container(
      margin: const EdgeInsets.only(
        top: 14,
        right: 24,
        bottom: 0,
      ),
      height: 110,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        color: grey100,
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            controller: secondScrollController,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 80,
              child: TextField(
                controller: commentTextController,
                style: const TextStyle(
                  fontSize: 14,
                  height: 19.6 / 14,
                  color: grey600,
                  letterSpacing: -0.3,
                ),
                cursorColor: primary600,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                maxLength: 500,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 16,
                  ),
                  hintText: '저장한 링크에 대해 간단하게 메모해보세요',
                  hintStyle: TextStyle(
                    color: grey400,
                    fontSize: 14,
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
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '${commentTextController.text.length}/500',
                style: const TextStyle(
                  color: grey400,
                  fontSize: 14,
                  letterSpacing: -0.3,
                  height: 16.7 / 14,
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
    return BlocBuilder<UploadLinkCubit, UploadResultState>(
      builder: (context, state) {
        final linkError = state == UploadResultState.error;
        return Container(
          margin: const EdgeInsets.only(
            top: 14,
            right: 24,
            bottom: 15,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: linkError ? redError2 : grey100),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  color: grey100,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  controller: firstScrollController,
                  child: SizedBox(
                    height: 80,
                    child: TextField(
                      controller: linkTextController,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 16.7 / 14,
                        color: grey600,
                        letterSpacing: -0.3,
                      ),
                      cursorColor: primary600,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 16,
                        ),
                        hintText: '링크를 여기에 불러주세요',
                        hintStyle: TextStyle(
                          color: grey400,
                          fontSize: 14,
                          letterSpacing: -0.3,
                        ),
                      ),
                      onChanged: (value) => setState(() {
                        if (value.isNotEmpty) {
                          buttonState = ButtonState.enabled;
                        }
                      }),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '링크 형식으로 입력해 주세요',
                  style: TextStyle(
                    color: linkError ? redError2 : Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 14.3 / 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void completeRegister(BuildContext context) {
    context
        .read<UploadLinkCubit>()
        .completeRegister(
          linkTextController.text,
          commentTextController.text,
          selectedFolderId,
        )
        .then((result) {
      if (result == UploadResultState.success) {
        Navigator.pop(context, NavigatorPopResult.saveLink);
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
    });
  }
}
