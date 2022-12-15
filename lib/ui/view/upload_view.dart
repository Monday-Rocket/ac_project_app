// ignore_for_file: avoid_positional_boolean_parameters

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_link_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/cubits/sign_up/button_state_cubit.dart';
import 'package:ac_project_app/ui/widget/bottom_dialog.dart';
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
  final firstScrollController = ScrollController();
  final secondScrollController = ScrollController();
  ButtonState buttonState = ButtonState.disabled;

  int selectedIndex = -1;

  int? selectedFolderId;

  @override
  void initState() {
    Future.microtask(() {
      final args = getArguments(context);
      final url = args['url'] as String? ?? '';
      linkTextController.text = url;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
                reverse: true,
                physics: const ClampingScrollPhysics(),
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.only(left: 24, top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildSubTitle('링크'),
                        buildLinkTextField(),
                        Container(
                          margin: const EdgeInsets.only(
                            right: 16,
                            bottom: 3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              buildSubTitle('폴더 선택'),
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
                        ),
                        buildFolderList(),
                        const SizedBox(height: 35),
                        buildSubTitle('링크 코멘트'),
                        Container(
                          margin: const EdgeInsets.only(
                            top: 14,
                            right: 24,
                            bottom: 90,
                          ),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            color: grey100,
                          ),
                          child: SingleChildScrollView(
                            controller: secondScrollController,
                            padding: EdgeInsets.zero,
                            child: SizedBox(
                              height: 80,
                              child: TextField(
                                controller: commentTextController,
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
                                  hintText: '저장한 링크에 대해 간단하게 메모해보세요',
                                  hintStyle: TextStyle(
                                    color: grey400,
                                    fontSize: 14,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: keyboardHeight,
                        )
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
              ),
            );
          },
        ),
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
        showPopUp(
          title: '저장완료!',
          content: '링크와 코멘트가 담겼어요',
          parentContext: context,
          callback: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
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

  BlocBuilder<GetFoldersCubit, FoldersState> buildFolderList() {
    return BlocBuilder<GetFoldersCubit, FoldersState>(
      builder: (folderContext, state) {
        if (state is FolderLoadedState) {
          final folders = state.folders;
          return Container(
            constraints: const BoxConstraints(
              minHeight: 115,
              maxHeight: 130,
            ),
            child: ListView.builder(
              itemCount: folders.length,
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                final folder = folders[index];
                final rightPadding = index != folders.length - 1 ? 12 : 24;
                final visible = folder.visible ?? false;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                      selectedFolderId = folder.id;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: rightPadding.toDouble(),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 95,
                              height: 95,
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(32)),
                                color: grey100,
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(32),
                                    ),
                                    child: ColoredBox(
                                      color: grey100,
                                      child: folder.thumbnail != null &&
                                          (folder.thumbnail?.isNotEmpty ??
                                              false)
                                          ? Image.network(
                                        folder.thumbnail!,
                                        width: 95,
                                        height: 95,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            emptyFolderView(),
                                      )
                                          : emptyFolderView(),
                                    ),
                                  ),
                                  if (!visible)
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 3),
                                        child: SvgPicture.asset(
                                          'assets/images/ic_lock.svg',
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                ],
                              ),
                            ),
                            Visibility(
                              visible: selectedIndex == index,
                              child: Container(
                                width: 95,
                                height: 95,
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(32)),
                                  color: secondary400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          folder.name ?? '',
                          style: const TextStyle(
                            color: grey700,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            letterSpacing: -0.3,
                            height: 14.3 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return const SizedBox(height: 115);
        }
      },
    );
  }

  double getBottomMargin(bool visible) {
    return visible ? 16 : 37;
  }

  Text buildSubTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 19 / 16,
        letterSpacing: -0.3,
        color: grey800,
      ),
    );
  }

  Container emptyFolderView() {
    return Container(
      width: 95,
      height: 95,
      color: primary100,
      child: Center(
        child: SvgPicture.asset(
          'assets/images/folder.svg',
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}
