import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/ui/page/my_folder/folder_visible_state.dart';
import 'package:ac_project_app/ui/widget/custom_reorderable_list_view.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyFolderPage extends StatefulWidget {
  const MyFolderPage({super.key});

  @override
  State<MyFolderPage> createState() => _MyFolderPageState();
}

class _MyFolderPageState extends State<MyFolderPage> {
  bool listIconState = true;

  final _textController = TextEditingController();

  final _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 105,
            height: 105,
            margin: const EdgeInsetsDirectional.only(top: 45, bottom: 6),
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
                      borderRadius: BorderRadius.all(Radius.circular(7)),
                    ),
                    margin: const EdgeInsets.only(right: 6),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        suffixIcon: Image.asset(
                          'assets/images/folder_search_icon.png',
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      listIconState = !listIconState;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: listIconState
                        ? SvgPicture.asset('assets/images/list_icon.svg')
                        : SvgPicture.asset('assets/images/grid_icon.svg'),
                  ),
                ),
                InkWell(
                  onTap: showAddFolderDialog,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: SvgPicture.asset('assets/images/btn_add.svg'),
                  ),
                ),
              ],
            ),
          ),
          Builder(
            builder: (context) {
              if (listIconState) {
                return buildListView();
              } else {
                return buildGridView();
              }
            },
          )
        ],
      ),
    );
  }

  Flexible buildGridView() {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          childAspectRatio: 159 / 214,
          children: List.generate(folders.length, (index) {
            final lockPrivate = folders[index].private ?? true;
            final isNullImage = folders[index].imageUrl == null ||
                (folders[index].imageUrl?.isEmpty ?? true);
            return GridTile(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(7),
                          ),
                          child: Image.network(
                            folders[index].imageUrl ?? '',
                            fit: BoxFit.fitHeight,
                            errorBuilder: (ctx, _, __) {
                              return ColoredBox(
                                color: grey100,
                                child: Center(
                                  child: SvgPicture.asset(
                                    width: 46,
                                    height: 46,
                                    'assets/images/folder_big.svg',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (lockPrivate)
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 10,
                                right: 10,
                              ),
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
                  Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 18,
                          ),
                          Text(
                            folders[index].name ?? '',
                            style: const TextStyle(
                              color: Color(0xFF13181E),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            '링크 ${addCommasFrom(folders[index].linkCount)}개',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF62666C),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: isNullImage
                            ? const SizedBox.shrink()
                            : Container(
                                margin: const EdgeInsets.only(top: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SvgPicture.asset(
                                    'assets/images/more.svg',
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget buildListView() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: CustomReorderableListView.separated(
          shrinkWrap: true,
          itemCount: folders.length,
          separatorBuilder: (ctx, index) =>
              const Divider(thickness: 1, height: 1),
          itemBuilder: (ctx, index) {
            final lockPrivate = folders[index].private ?? true;
            final isNullImage = folders[index].imageUrl == null ||
                (folders[index].imageUrl?.isEmpty ?? true);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              key: Key('$index'),
              title: Container(
                margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
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
                                child: Image.network(
                                  folders[index].imageUrl ?? '',
                                  width: 63,
                                  height: 63,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, _, __) {
                                    return Container(
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
                                    );
                                  },
                                ),
                              ),
                              if (lockPrivate)
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
                              folders[index].name!,
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
                              '링크 ${addCommasFrom(folders[index].linkCount)}개',
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
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset('assets/images/more.svg'),
                      ),
                  ],
                ),
              ),
            );
          },
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              Log.i('old: $oldIndex, new: $newIndex');
              final item = folders.removeAt(oldIndex);
              folders.insert(newIndex, item);
            });
          },
        ),
      ),
    );
  }

  final isSelected = [true, false];
  final folders = [
    Folder(
      name: '미분류',
      private: true,
      linkCount: 20,
    ),
    Folder(
      imageUrl:
          'https://play-lh.googleusercontent.com/Kbu0747Cx3rpzHcSbtM1zDriGFG74zVbtkPmVnOKpmLCS59l7IuKD5M3MKbaq_nEaZM',
      name: '디자인',
      private: true,
      linkCount: 30,
    ),
    Folder(
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/1667px-Apple_logo_black.svg.png',
      name: 'Apple',
      private: false,
      linkCount: 12345,
    ),
  ];

  Future<bool?> showAddFolderDialog() async {
    return showModalBottomSheet<bool>(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        var isEmptyName = true;
        var folderPrivate = FolderVisibleState.visible;
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
                              child: const Text('새로운 폴더').bold().fontSize(20),
                            ),
                            Container(
                              alignment: Alignment.topRight,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
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
                                key: _formKey,
                                child: TextFormField(
                                  autofocus: true,
                                  controller: _textController,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: grey800,
                                  ),
                                  decoration: InputDecoration(
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: primary800),
                                    ),
                                    suffix: isEmptyName
                                        ? const SizedBox.shrink()
                                        : InkWell(
                                            onTap: () {
                                              setState(() {
                                                _textController.text = '';
                                              });
                                            },
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 19,
                                            ),
                                          ),
                                    hintStyle: const TextStyle(
                                      color: grey500,
                                      fontSize: 17,
                                    ),
                                    hintText: '새로운 폴더 이름',
                                  ),
                                  onChanged: (String? value) {
                                    setState(() {
                                      isEmptyName = value?.isEmpty ?? true;
                                    });
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
                          margin: const EdgeInsets.only(top: 50),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(55),
                              backgroundColor:
                                  isEmptyName ? secondary : primary600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isEmptyName
                                ? doNothing
                                : () => saveEmptyFolder(
                                      context,
                                      _textController.text,
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
                );
              },
            ),
          ],
        );
      },
    );
  }

  /* TODO
      1. 폴더 저장
      2. 다이얼로그 닫기
      3. 화면 업데이트 (리스트 재조회) */
  void saveEmptyFolder(
      BuildContext context, String text, FolderVisibleState folderPrivate) {
    Log.i('폴더 저장');
    Navigator.pop(context);
  }

  void doNothing() {}
}
