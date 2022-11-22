import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/my_link/get_selected_folder_cubit.dart';
import 'package:ac_project_app/cubits/my_link/link_list_state.dart';
import 'package:ac_project_app/cubits/my_link/links_from_selected_folder_cubit.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyLinkPage extends StatelessWidget {
  const MyLinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = getArguments(context);
    final folders = arguments['folders'] as List<Folder>;
    final tabIndex = arguments['tabIndex'] as int;

    final width = MediaQuery.of(context).size.width;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetSelectedFolderCubit(folders[tabIndex]),
        ),
        BlocProvider(
          create: (_) => LinksFromSelectedFolderCubit(folders[tabIndex], 0),
        ),
      ],
      child: BlocBuilder<GetSelectedFolderCubit, Folder>(
        builder: (context, folder) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTitleBar(folder),
                  buildContentsCountText(folder),
                  buildSearchBar(),
                  buildTabBar(folders, tabIndex, folder),
                  buildListView(folder, width),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Container buildTitleBar(Folder folder) {
    final classified = folder.isClassified ?? true;
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 12, top: 39),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                classified ? folder.name! : '미분류',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  height: 36 / 30,
                ),
              ),
              if (!(folder.visible ?? false))
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: SvgPicture.asset(
                    'assets/images/ic_lock.svg',
                  ),
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
    );
  }

  Container buildContentsCountText(Folder folder) {
    return Container(
      margin: const EdgeInsets.only(left: 24, top: 3),
      child: Text(
        '콘텐츠 ${addCommasFrom(folder.links)}개',
        style: const TextStyle(
          color: greyText,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 24.5 / 14,
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
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
    );
  }

  Widget buildTabBar(List<Folder> folders, int tabIndex, Folder folder) {
    return Container(
      margin: const EdgeInsets.only(
        top: 30,
        left: 12,
        right: 20,
      ),
      child: DefaultTabController(
        length: folders.length,
        initialIndex: tabIndex,
        child: SizedBox(
          height: 36,
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
                    for (final folder in folders) {
                      tabs.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                          ),
                          child: Text(
                            folder.name ?? '',
                          ),
                        ),
                      );
                    }
                    return TabBar(
                      isScrollable: true,
                      physics: const ClampingScrollPhysics(),
                      unselectedLabelColor: grey700,
                      labelColor: primaryTab,
                      labelStyle: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        height: 19 / 16,
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        height: 19 / 16,
                        fontWeight: FontWeight.bold,
                      ),
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(
                          color: primaryTab,
                          width: 2.5,
                        ),
                        insets: EdgeInsets.symmetric(horizontal: 15),
                      ),
                      tabs: tabs,
                      onTap: (index) {
                        context
                            .read<GetSelectedFolderCubit>()
                            .update(folders[index]);
                        context
                            .read<LinksFromSelectedFolderCubit>()
                            .getSelectedLinks(folders[index], 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildListView(Folder folder, double width) {
    if (folder.links == 0) {
      return buildEmptyList();
    } else {
      return BlocBuilder<LinksFromSelectedFolderCubit, LinkListState>(
        builder: (context, state) {
          if (state is LinkListLoadedState) {
            final links = state.links;
            return Expanded(
              child: ListView.separated(
                itemCount: links.length,
                itemBuilder: (_, index) {
                  final link = links[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 24,
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: (width - 24 * 2) - 159 - 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      link.title ?? '',
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: blackBold,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      link.describe ?? '\n\n',
                                      maxLines: 2,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: greyText,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 30),
                                  child: Text(
                                    link.url ?? '',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFC0C2C4),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(7),
                            ),
                            child: ColoredBox(
                              color: grey100,
                              child: Image.network(
                                link.image ?? '',
                                width: 159,
                                height: 116,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return SizedBox(
                                    width: 159,
                                    height: 116,
                                    child: Image.asset(
                                      'assets/images/profile/img_01_on.png',
                                      width: 105,
                                      height: 105,
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(height: 1, color: greyTab);
                },
              ),
            );
          } else {
            return buildEmptyList();
          }
        },
      );
    }
  }

  Expanded buildEmptyList() {
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
  }
}
