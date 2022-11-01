import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/ui/widget/custom_reorderable_list_view.dart';
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
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
              color: Colors.black,
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
                  onTap: () {},
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
                return Expanded(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            margin:
                                                const EdgeInsets.only(top: 8),
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
            },
          )
        ],
      ),
    );
  }

  Container buildListView() {
    return Container(
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
}
