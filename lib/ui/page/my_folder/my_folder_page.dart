// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/my_folder/add_new_folder.dart';
import 'package:ac_project_app/cubits/my_folder/delete_folder.dart';
import 'package:ac_project_app/cubits/my_folder/folder_view_type_cubit.dart';
import 'package:ac_project_app/cubits/my_folder/folders_state.dart';
import 'package:ac_project_app/cubits/my_folder/get_folders_cubit.dart';
import 'package:ac_project_app/cubits/my_folder/search_folder_name_cubit.dart';
import 'package:ac_project_app/cubits/my_folder/transfer_folder_visible.dart';
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
        BlocProvider<SearchFolderNameCubit>(
          create: (_) => SearchFolderNameCubit(),
        ),
      ],
      child: BlocBuilder<FolderViewTypeCubit, FolderViewType>(
        builder: (context, folderViewType) {
          // TODO 유저 이미지
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/my_folder_back.png',
                  width: width,
                  fit: BoxFit.fitWidth,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 105,
                      height: 105,
                      margin:
                          const EdgeInsetsDirectional.only(top: 90, bottom: 6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.lightGreenAccent,
                      ),
                    ),
                    const Text(
                      '테스트',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Color(0xff0e0e0e),
                      ),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  prefixIcon: Image.asset(
                                    'assets/images/folder_search_icon.png',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => showAddFolderDialog(context),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child:
                                  SvgPicture.asset('assets/images/btn_add.svg'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<GetFoldersCubit, FoldersState>(
                      builder: (getFolderContext, state) {
                        if (state is LoadingState) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is ErrorState) {
                          return const Center(
                            child: Icon(Icons.close),
                          );
                        } else if (state is LoadedState) {
                          if (state.folders.isEmpty) {
                            return const Expanded(
                              child: Center(
                                child: Text(
                                  '등록된 링크가 없습니다',
                                  style: TextStyle(
                                    color: grey300,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return buildListView(state.folders, context);
                          }
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    )
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildListView(List<Folder> folders, BuildContext context) {
    return BlocBuilder<SearchFolderNameCubit, String>(
        builder: (context, searchName) {
      // TODO folders에서 name 여부 찾아서 필터링 하기

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
              final lockPrivate = folder.private ?? true;
              final isNullImage =
                  folder.imageUrl == null || (folder.imageUrl?.isEmpty ?? true);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                key: Key('$index'),
                title: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.myLinks,
                      arguments: {
                        'folder': folder,
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
                                    child: folder.imageUrl != null
                                        ? Image.network(
                                            folder.imageUrl!,
                                            width: 63,
                                            height: 63,
                                            fit: BoxFit.contain,
                                          )
                                        : Container(
                                            width: 63,
                                            height: 63,
                                            color: grey100,
                                            child: Center(
                                              child: SvgPicture.asset(
                                                'assets/images/folder.svg',
                                                width: 24,
                                                height: 24,
                                              ),
                                            ),
                                          ),
                                  ),
                                  if (lockPrivate)
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
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  folder.name!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF13181E),
                                  ),
                                ),
                                const SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  '링크 ${addCommasFrom(folder.linkCount)}개',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF62666C),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                        if (isNullImage)
                          const SizedBox.shrink()
                        else
                          InkWell(
                            onTap: () =>
                                showFolderOptionsDialog(folder, context),
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
    });
  }

  Future<bool?> showAddFolderDialog(BuildContext context) async {
    return showModalBottomSheet<bool>(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        var isEmptyName = true;
        var folderPrivate = FolderVisibleState.visible;
        final textController = TextEditingController();
        return BlocProvider(
          create: (_) => AddNewFolderCubit(),
          child: Wrap(
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  return GestureDetector(
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
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Center(
                                  child:
                                      const Text('새로운 폴더').bold().fontSize(20),
                                ),
                                Container(
                                  alignment: Alignment.topRight,
                                  child: InkWell(
                                    onTap: () => saveEmptyFolder(
                                      context,
                                      textController.text,
                                      folderPrivate,
                                    ),
                                    child: Text(
                                      '완료',
                                      style: TextStyle(
                                        color: isEmptyName ? grey300 : grey800,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 60),
                                  child: Form(
                                    key: GlobalKey(),
                                    child: TextFormField(
                                      autofocus: true,
                                      controller: textController,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: grey800,
                                      ),
                                      decoration: InputDecoration(
                                        focusedBorder:
                                            const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primary800,
                                            width: 2,
                                          ),
                                        ),
                                        suffix: isEmptyName
                                            ? const SizedBox.shrink()
                                            : InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    textController.text = '';
                                                  });
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
                                      onChanged: (String? value) {
                                        setState(() {
                                          isEmptyName = value?.isEmpty ?? true;
                                        });
                                      },
                                      onFieldSubmitted: (value) {
                                        saveEmptyFolder(
                                          context,
                                          value,
                                          folderPrivate,
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
                                    onTap: () {
                                      setState(() {
                                        folderPrivate = folderPrivate.toggle();
                                      });
                                    },
                                    child: folderPrivate ==
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
                            Container(
                              margin:
                                  const EdgeInsets.only(top: 50, bottom: 20),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(55),
                                  backgroundColor:
                                      isEmptyName ? secondary : primary600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => saveEmptyFolder(
                                  context,
                                  textController.text,
                                  folderPrivate,
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
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /* TODO
      1. 폴더 저장
      2. 다이얼로그 닫기
      3. 화면 업데이트 (리스트 재조회) */
  void saveEmptyFolder(
    BuildContext context,
    String folderName,
    FolderVisibleState folderPrivate,
  ) {
    if (folderName.isEmpty) {
      return;
    }
    // TODO 폴더 저장 API 호출
    final folder = Folder(
      name: folderName,
      private: folderPrivate == FolderVisibleState.visible,
    );

    context.read<AddNewFolderCubit>().add(folder).then((result) {
      Log.i('폴더 저장');
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: '                새로운 폴더가 생성되었어요!                ',
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: grey900,
        textColor: Colors.white,
        fontSize: 13,
      );
      Navigator.pushNamed(context, Routes.myLinks, arguments: {});
    });
  }

  Future<bool?> showFolderOptionsDialog(
    Folder folder,
    BuildContext context,
  ) async {
    final lockPrivate = folder.private ?? false;
    return showModalBottomSheet<bool?>(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            StatefulBuilder(
              builder: (context, setState) {
                return DecoratedBox(
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
                              BlocProvider(
                                create: (_) => TransferFolderVisibleCubit(),
                                child: InkWell(
                                  onTap: () =>
                                      changeFolderVisible(context, folder),
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
                                        lockPrivate ? '공개로 전환' : '비공개로 전환',
                                        style: const TextStyle(
                                          color: Color(0xFF13181E),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              BlocProvider(
                                create: (_) => DeleteFolderCubit(),
                                child: InkWell(
                                  onTap: () => deleteFolder(context, folder),
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
                                          color: Color(0xFF13181E),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
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
                );
              },
            ),
          ],
        );
      },
    );
  }

  void changeFolderVisible(BuildContext context, Folder folder) {
    // TODO 공개여부 변경 API
    context.read<TransferFolderVisibleCubit>().change(folder).then((value) {
      Navigator.pop(context);
    });
  }

  void deleteFolder(BuildContext context, Folder folder) {
    showDialog<bool?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            width: 285,
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
                        // TODO 삭제 API 호출 및 결과 리턴
                        context
                            .read<DeleteFolderCubit>()
                            .delete(folder)
                            .then((value) {
                          Navigator.pop(context, true);
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
