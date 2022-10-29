import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyFolderPage extends StatefulWidget {
  const MyFolderPage({super.key});

  @override
  State<MyFolderPage> createState() => _MyFolderPageState();
}

class _MyFolderPageState extends State<MyFolderPage> {
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
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: grey100,
                      borderRadius: BorderRadius.all(Radius.circular(7)),
                    ),
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
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SvgPicture.asset('assets/images/list_icon.svg'),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SvgPicture.asset('assets/images/btn_add.svg'),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: folders.length,
              separatorBuilder: (ctx, index) => const Divider(
                thickness: 1,
                height: 1,
              ),
              itemBuilder: (ctx, index) {
                
                final lockPrivate = folders[index].private ?? true;
                
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 63 + 6,
                        height: 63,
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
                            if (lockPrivate) Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: SvgPicture.asset('assets/images/ic_lock.svg'),
                              ),
                            ) else const SizedBox.shrink(),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
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
