import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyLinkView extends StatelessWidget {
  const MyLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = getArguments(context);
    final folder = arguments['folder'] as Folder;
    final tabIndex = arguments['tabIndex'] as int;
    final selectedFolderName = folder.name ?? '';
    final visible = folder.visible ?? false;
    final linkCount = folder.linkCount ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 24, right: 12, top: 39),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        selectedFolderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          height: 36 / 30,
                        ),
                      ),
                      if (!visible)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: SvgPicture.asset('assets/images/ic_lock.svg'),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                  InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SvgPicture.asset('assets/images/more.svg'),
                    ),
                  )
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 24, top: 3),
              child: Text(
                '콘텐츠 ${addCommasFrom(linkCount)}개',
                style: const TextStyle(
                  color: greyText,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 24.5 / 14,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 23, left: 23, right: 23),
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
                        onChanged: (value) {
                          // context.read<GetFoldersCubit>().filter(value);
                        },
                      ),
                    ),
                  ),
                  InkWell(
                    // onTap: () => showAddFolderDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: SvgPicture.asset('assets/images/btn_add.svg'),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 30 - 7, left: 12, right: 20),
              child: DefaultTabController(
                length: 5,
                initialIndex: tabIndex,
                child: SizedBox(
                  height: 32,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 15,
                            right: 11,
                            bottom: 1,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  color: greyTab,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 7),
                        child: Builder(
                          builder: (context) {
                            final tabs = <Widget>[];
                            for (final folder in getFolderNameList()) {
                              tabs.add(
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 7),
                                  child: Text(
                                    folder.name ?? '',
                                  ),
                                ),
                              );
                            }
                            return TabBar(
                              isScrollable: true,
                              unselectedLabelColor: grey700,
                              labelColor: primaryTab,
                              labelStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              indicator: const UnderlineTabIndicator(
                                borderSide:
                                    BorderSide(color: primaryTab, width: 2.5),
                                insets: EdgeInsets.symmetric(horizontal: 15),
                              ),
                              tabs: tabs,
                            );
                          },
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
    );
  }

  List<Folder> getFolderNameList() {
    return [
      Folder(
        name: '미분류',
        visible: false,
        linkCount: 20,
      ),
      Folder(
        imageUrl:
            'https://play-lh.googleusercontent.com/Kbu0747Cx3rpzHcSbtM1zDriGFG74zVbtkPmVnOKpmLCS59l7IuKD5M3MKbaq_nEaZM',
        name: '디자인1',
        visible: true,
        linkCount: 30,
      ),
      Folder(
        imageUrl:
            'https://play-lh.googleusercontent.com/Kbu0747Cx3rpzHcSbtM1zDriGFG74zVbtkPmVnOKpmLCS59l7IuKD5M3MKbaq_nEaZM',
        name: '디자인2',
        visible: false,
        linkCount: 30,
      ),
      Folder(
        imageUrl:
            'https://play-lh.googleusercontent.com/Kbu0747Cx3rpzHcSbtM1zDriGFG74zVbtkPmVnOKpmLCS59l7IuKD5M3MKbaq_nEaZM',
        name: '디자인3',
        visible: true,
        linkCount: 30,
      ),
      Folder(
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/1667px-Apple_logo_black.svg.png',
        name: 'Apple',
        visible: false,
        linkCount: 12345,
      ),
    ];
  }
}
