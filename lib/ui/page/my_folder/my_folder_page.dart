// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folder_name_cubit.dart';
import 'package:ac_project_app/cubits/folders/folder_view_type_cubit.dart';
import 'package:ac_project_app/cubits/folders/folder_visible_cubit.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/cubits/sign_up/button_state_cubit.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/my_folder/folder_visible_state.dart';
import 'package:ac_project_app/ui/widget/custom_reorderable_list_view.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MyFolderPage extends StatelessWidget {
  const MyFolderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return MultiBlocProvider(
      providers: [
        BlocProvider<FolderViewTypeCubit>(
          create: (_) => FolderViewTypeCubit(),
        ),
        BlocProvider<GetFoldersCubit>(
          create: (_) => GetFoldersCubit(),
        ),
      ],
      child: BlocBuilder<FolderViewTypeCubit, FolderViewType>(
        builder: (context, folderViewType) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/my_folder_back.png',
                  width: width,
                  fit: BoxFit.fill,
                ),
                BlocBuilder<GetFoldersCubit, FoldersState>(
                  builder: (getFolderContext, folderState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BlocBuilder<GetProfileInfoCubit, ProfileState>(
                          builder: (context, state) {
                            if (state is ProfileLoadedState) {
                              final profile = state.profile;
                              return InkWell(
                                onTap: () {
                                  // FIXME Reload Image
                                  context
                                      .read<GetProfileInfoCubit>()
                                      .loadProfileData();
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 105,
                                      height: 105,
                                      margin: const EdgeInsetsDirectional.only(
                                        top: 90,
                                        bottom: 6,
                                      ),
                                      child: Image.asset(profile.profileImage),
                                    ),
                                    Text(
                                      profile.nickname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28,
                                        color: Color(0xff0e0e0e),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                        Container(
                          margin: const EdgeInsetsDirectional.only(
                            top: 50,
                            start: 20,
                            end: 20,
                            bottom: 6,
                          ),
                          child: Row(
                            children: [
                              Flexible(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: grey100,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(7)),
                                  ),
                                  margin: const EdgeInsets.only(right: 6),
                                  child: TextField(
                                    textAlignVertical: TextAlignVertical.center,
                                    cursorColor: grey800,
                                    style: const TextStyle(
                                      color: grey800,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      prefixIcon: Image.asset(
                                        'assets/images/folder_search_icon.png',
                                      ),
                                    ),
                                    onChanged: (value) {
                                      context
                                          .read<GetFoldersCubit>()
                                          .filter(value);
                                    },
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => showAddFolderDialog(context),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: SvgPicture.asset(
                                    'assets/images/btn_add.svg',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            if (folderState is FolderLoadingState) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (folderState is FolderErrorState) {
                              Log.e(folderState.props[0]);
                              return const Center(
                                child: Icon(Icons.close),
                              );
                            } else if (folderState is FolderLoadedState) {
                              if (folderState.folders.isEmpty) {
                                return const Expanded(
                                  child: Center(
                                    child: Text(
                                      '등록된 폴더가 없습니다',
                                      style: TextStyle(
                                        color: grey300,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return buildListView(
                                  folderState.folders,
                                  context,
                                );
                              }
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildListView(List<Folder> folders, BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: CustomReorderableListView.separated(
          shrinkWrap: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: folders.length,
          separatorBuilder: (ctx, index) =>
              const Divider(thickness: 1, height: 1),
          itemBuilder: (ctx, index) {
            final folder = folders[index];
            final visible = folder.visible ?? true;
            final isNotClassified = folder.name == '미분류';

            return ListTile(
              contentPadding: EdgeInsets.zero,
              key: Key('$index'),
              title: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Routes.myLinks,
                    arguments: {
                      'folders': folders,
                      'tabIndex': index,
                    },
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 63 + 6,
                            height: 63,
                            margin: const EdgeInsets.only(right: 30),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  child: ColoredBox(
                                    color: grey100,
                                    child: folder.thumbnail != null &&
                                            (folder.thumbnail?.isNotEmpty ??
                                                false)
                                        ? Image.network(
                                            folder.thumbnail!,
                                            width: 63,
                                            height: 63,
                                            fit: BoxFit.contain,
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
                                      padding: const EdgeInsets.only(bottom: 3),
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
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                folder.name!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: blackBold,
                                ),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Text(
                                '링크 ${addCommasFrom(folder.links)}개',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: greyText,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                      if (isNotClassified)
                        const SizedBox.shrink()
                      else
                        InkWell(
                          onTap: () => showFolderOptionsDialog(folder, context),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset('assets/images/more.svg'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          onReorder: (int oldIndex, int newIndex) {
            Log.i('old: $oldIndex, new: $newIndex');
            final item = folders.removeAt(oldIndex);
            folders.insert(newIndex, item);
          },
        ),
      ),
    );
  }

  Container emptyFolderView() {
    return Container(
      width: 63,
      height: 63,
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

  Future<bool?> showAddFolderDialog(BuildContext parentContext) async {
    final formKey = GlobalKey<FormState>();

    return showModalBottomSheet<bool>(
      backgroundColor: Colors.transparent,
      context: parentContext,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => ButtonStateCubit(),
            ),
            BlocProvider(
              create: (_) => FolderNameCubit(),
            ),
            BlocProvider(
              create: (_) => FolderVisibleCubit(),
            ),
          ],
          child: Wrap(
            children: [
              GestureDetector(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 30,
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: BlocBuilder<FolderVisibleCubit, FolderVisibleState>(
                      builder: (context, visibleState) {
                        return Column(
                          children: [
                            Stack(
                              children: [
                                Center(
                                  child:
                                      const Text('새로운 폴더').bold().fontSize(20),
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
                                          visibleState,
                                        ),
                                        child: Text(
                                          '완료',
                                          style: TextStyle(
                                            color: state == ButtonState.disabled
                                                ? grey300
                                                : grey800,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 60),
                                  child: Form(
                                    key: formKey,
                                    child: TextFormField(
                                      autofocus: true,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: grey800,
                                      ),
                                      cursorColor: primary600,
                                      decoration: InputDecoration(
                                        focusedBorder:
                                            const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primary800,
                                            width: 2,
                                          ),
                                        ),
                                        suffix: context
                                                .read<FolderNameCubit>()
                                                .state
                                                .isEmpty
                                            ? const SizedBox.shrink()
                                            : InkWell(
                                                onTap: () {
                                                  context
                                                      .read<FolderNameCubit>()
                                                      .update('');
                                                  context
                                                      .read<ButtonStateCubit>()
                                                      .disable();
                                                },
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  size: 19,
                                                ),
                                              ),
                                        hintStyle: const TextStyle(
                                          color: grey400,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        hintText: '새로운 폴더 이름',
                                      ),
                                      validator: (value) {
                                        return null;
                                      },
                                      onChanged: (String? value) {
                                        if (value?.isEmpty ?? true) {
                                          context
                                              .read<ButtonStateCubit>()
                                              .disable();
                                        } else {
                                          context
                                              .read<ButtonStateCubit>()
                                              .enable();
                                          context
                                              .read<FolderNameCubit>()
                                              .update(value!);
                                        }
                                      },
                                      onFieldSubmitted: (value) {
                                        saveEmptyFolder(
                                          context,
                                          parentContext,
                                          value,
                                          visibleState,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              child: Row(
                                children: [
                                  const Text(
                                    '비공개 폴더',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: grey800,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  InkWell(
                                    onTap: context
                                        .read<FolderVisibleCubit>()
                                        .toggle,
                                    child: visibleState ==
                                            FolderVisibleState.invisible
                                        ? SvgPicture.asset(
                                            'assets/images/toggle_on.svg',
                                          )
                                        : SvgPicture.asset(
                                            'assets/images/toggle_off.svg',
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            BlocBuilder<ButtonStateCubit, ButtonState>(
                              builder: (context, state) {
                                return Container(
                                  margin: const EdgeInsets.only(
                                    top: 50,
                                    bottom: 20,
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(55),
                                      backgroundColor:
                                          state == ButtonState.disabled
                                              ? secondary
                                              : primary600,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => saveEmptyFolder(
                                      context,
                                      parentContext,
                                      context.read<FolderNameCubit>().state,
                                      visibleState,
                                    ),
                                    child: const Text(
                                      '폴더에 저장하기',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textWidthBasis: TextWidthBasis.parent,
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void saveEmptyFolder(
    BuildContext context,
    BuildContext parentContext,
    String folderName,
    FolderVisibleState visibleState,
  ) {
    if (folderName.isEmpty) {
      return;
    }

    final folder = Folder(
      name: folderName,
      visible: visibleState == FolderVisibleState.visible,
    );

    context.read<FolderNameCubit>().add(folder).then((result) {
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: '                새로운 폴더가 생성되었어요!                ',
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: grey900,
        textColor: Colors.white,
        fontSize: 13,
      );

      parentContext.read<GetFoldersCubit>().getFolders().then((_) {
        final folders = parentContext.read<GetFoldersCubit>().folders;
        Navigator.pushNamed(
          parentContext,
          Routes.myLinks,
          arguments: {
            'folders': folders,
            'tabIndex': folders.length - 1,
          },
        );
      });
    });
  }

  Future<bool?> showFolderOptionsDialog(
    Folder folder,
    BuildContext parentContext,
  ) async {
    final visible = folder.visible ?? false;
    return showModalBottomSheet<bool?>(
      backgroundColor: Colors.transparent,
      context: parentContext,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 29,
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 30, right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '폴더 옵션',
                            style: TextStyle(
                              color: grey800,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 17,
                        left: 6,
                        right: 6,
                        bottom: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => changeFolderVisible(
                              parentContext,
                              folder,
                            ),
                            highlightColor: grey100,
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              padding: const EdgeInsets.only(
                                top: 14,
                                bottom: 14,
                                left: 24,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  visible ? '비공개로 전환' : '공개로 전환',
                                  style: const TextStyle(
                                    color: blackBold,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => deleteFolder(parentContext, folder),
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                color: Colors.transparent,
                              ),
                              padding: const EdgeInsets.only(
                                top: 14,
                                bottom: 14,
                                left: 24,
                              ),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '폴더 삭제',
                                  style: TextStyle(
                                    color: blackBold,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void changeFolderVisible(BuildContext context, Folder folder) {
    context.read<GetFoldersCubit>().transferVisible(folder).then((value) {
      Navigator.pop(context);
    });
  }

  void deleteFolder(BuildContext context, Folder folder) {
    final width = MediaQuery.of(context).size.width;
    showDialog<bool?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            width: width - 45 * 2,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 24,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2, bottom: 10),
                    child: const Text(
                      '폴더를 삭제하시겠어요?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: grey900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Text(
                    '폴더를 삭제하면, 폴더 안에 있는\n콘텐츠도 사라져요',
                    style: TextStyle(
                      color: grey500,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                      top: 33,
                      left: 6,
                      right: 6,
                      bottom: 6,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: primary600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        final cubit = context.read<GetFoldersCubit>();
                        cubit.delete(folder).then((value) {
                          Navigator.pop(context, true);
                          cubit.getFolders();
                        });
                      },
                      child: const Text(
                        '삭제하기',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ).bold(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((bool? value) {
      Navigator.pop(context);
      if (value ?? false) {
        Fluttertoast.showToast(
          msg: '                  폴더가 삭제되었어요!                  ',
          gravity: ToastGravity.BOTTOM,
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: grey900,
          textColor: Colors.white,
          fontSize: 13,
        );
      }
    });
  }
}
