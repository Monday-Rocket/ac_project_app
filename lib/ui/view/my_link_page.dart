import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_selected_folder_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_folder_cubit.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/resource.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/only_back_app_bar.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final links = <Link>[];

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
            appBar: buildBackAppBar(context),
            body: SafeArea(
              child: BlocBuilder<LinksFromSelectedFolderCubit, LinkListState>(
                builder: (cubitContext, state) {
                  return Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildTitleBar(folder),
                          buildContentsCountText(folder),
                          buildSearchBar(context),
                          buildTabBar(folders, tabIndex, folder, links),
                          buildBodyList(
                            folder: folder,
                            width: width,
                            context: cubitContext,
                            totalLinks: links,
                            state: state,
                          ),
                        ],
                      ),
                      if (state is LinkListLoadingState ||
                          state is LinkListInitialState)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 30),
                            child: const CircularProgressIndicator(
                              color: primary600,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  );
                },
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
      margin: const EdgeInsets.only(left: 24, right: 12, top: 10),
      child: Row(
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

  Widget buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 23, left: 23, right: 23),
      child: Row(
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                Routes.search,
                arguments: {
                  'isMine': true,
                },
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: grey100,
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                ),
                margin: const EdgeInsets.only(right: 6),
                child: TextField(
                  enabled: false,
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

  Widget buildTabBar(List<Folder> folders, int tabIndex, Folder folder,
      List<Link> totalLinks) {
    return Container(
      margin: const EdgeInsets.only(top: 30, left: 12, right: 20),
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
                      unselectedLabelColor: lightGrey700,
                      labelColor: primaryTab,
                      labelStyle: const TextStyle(
                        fontFamily: R_Font.PRETENDARD,
                        fontSize: 16,
                        height: 19 / 16,
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: R_Font.PRETENDARD,
                        fontSize: 16,
                        height: 19 / 16,
                        fontWeight: FontWeight.bold,
                      ),
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(
                          color: primaryTab,
                          width: 2.5,
                        ),
                        insets: EdgeInsets.only(
                          left: 15,
                          right: 15,
                        ),
                      ),
                      tabs: tabs,
                      onTap: (index) {
                        totalLinks.clear();
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

  Widget buildBodyList({
    required Folder folder,
    required double width,
    required BuildContext context,
    required List<Link> totalLinks,
    required LinkListState state,
  }) {
    if (folder.links == 0) {
      return buildEmptyList();
    } else {
      if (state is LinkListLoadedState) {
        final links = state.links;
        totalLinks.addAll(links);
      }
      return Expanded(
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (scrollEnd) {
            final metrics = scrollEnd.metrics;
            if (metrics.atEdge && metrics.pixels != 0) {
              context.read<LinksFromSelectedFolderCubit>().loadMore();
            }
            return true;
          },
          child: ListView.separated(
            itemCount: totalLinks.length,
            itemBuilder: (_, index) {
              final link = totalLinks[index];
              return InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Routes.linkDetail,
                    arguments: {
                      'link': link,
                      'isMine': true,
                    },
                  ).then((result) {
                    if (result == 'deleted') {
                      Navigator.pop(context);
                    } else {
                      // update
                      totalLinks.clear();
                      context
                          .read<LinksFromSelectedFolderCubit>()
                          .getSelectedLinks(folder, 0);
                    }
                  });
                },
                child: Container(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  const SizedBox(
                                    height: 7,
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
                            child: link.image != null && link.image!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: link.image ?? '',
                                    imageBuilder: (context, imageProvider) =>
                                        Container(
                                      width: 159,
                                      height: 116,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) {
                                      return const SizedBox();
                                    },
                                  )
                                : const SizedBox(
                                    width: 159,
                                    height: 116,
                                  ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider(height: 1, color: greyTab);
            },
          ),
        ),
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
