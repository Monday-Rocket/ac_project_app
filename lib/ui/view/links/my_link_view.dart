import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_selected_folder_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_folder_cubit.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/resource.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/only_back_app_bar.dart';
import 'package:ac_project_app/ui/widget/slidable/link_slidable_widget.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyLinkView extends StatelessWidget {
  const MyLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = getArguments(context);
    final tabIndex = arguments['tabIndex'] as int;
    var folders = arguments['folders'] as List<Folder>;
    final width = MediaQuery.of(context).size.width;
    final links = <Link>[];

    return BlocProvider(
      create: (_) => GetFoldersCubit(),
      child: BlocBuilder<GetFoldersCubit, FoldersState>(
        builder: (foldersContext, folderState) {
          if (folderState is FolderLoadedState) {
            folders = folderState.folders;
          }

          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => GetSelectedFolderCubit(folders[tabIndex]),
              ),
              BlocProvider(
                create: (_) =>
                    LinksFromSelectedFolderCubit(folders[tabIndex], 0),
              ),
            ],
            child: BlocBuilder<GetSelectedFolderCubit, Folder>(
              builder: (context, folder) {
                return Scaffold(
                  appBar: buildBackAppBar(context),
                  backgroundColor: Colors.white,
                  body: SafeArea(
                    child: BlocBuilder<LinksFromSelectedFolderCubit,
                        LinkListState>(
                      builder: (cubitContext, state) {
                        return Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildTitleBar(folder),
                                buildContentsCountText(cubitContext),
                                buildSearchBar(context, links),
                                buildTabBar(
                                  folders,
                                  tabIndex,
                                  folder,
                                  links,
                                  onChangeIndex: (int index) {
                                    // tabIndex = index;
                                  },
                                ),
                                buildBodyList(
                                  folder: folder,
                                  width: width,
                                  context: cubitContext,
                                  totalLinks: links,
                                  state: state,
                                  folderState: folderState,
                                  foldersContext: foldersContext,
                                ),
                              ],
                            ),
                            if (state is LinkListLoadingState ||
                                state is LinkListInitialState)
                              Center(
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
              child: Assets.images.icLockPng.image(),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Container buildContentsCountText(BuildContext context) {
    final count = context.read<LinksFromSelectedFolderCubit>().totalCount;
    return Container(
      margin: const EdgeInsets.only(left: 24, top: 3),
      child: Text(
        '콘텐츠 ${addCommasFrom(count)}개',
        style: const TextStyle(
          color: greyText,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget buildSearchBar(BuildContext context, List<Link> totalLinks) {
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
                  color: ccGrey100,
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                ),
                width: double.infinity,
                height: 36,
                margin: const EdgeInsets.only(right: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Assets.images.folderSearchIcon.image(),
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(context, Routes.upload).then((_) {
              // update
              totalLinks.clear();
              context.read<GetFoldersCubit>().getFolders();
            }),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SvgPicture.asset(Assets.images.btnAdd),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabBar(
    List<Folder> folders,
    int tabIndex,
    Folder folder,
    List<Link> totalLinks, {
    required void Function(int index) onChangeIndex,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 30, left: 12, right: 20),
      padding: const EdgeInsets.only(bottom: 18),
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
                      labelPadding: const EdgeInsets.symmetric(horizontal: 13),
                      tabs: tabs,
                      onTap: (index) {
                        onChangeIndex.call(index);
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
    required FoldersState folderState,
    required BuildContext foldersContext,
  }) {
    if (folder.links == 0) {
      return buildEmptyList();
    } else {
      if (state is LinkListLoadedState && folderState is FolderLoadedState) {
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
                  context.read<LinksFromSelectedFolderCubit>().loading();
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

                      foldersContext.read<GetFoldersCubit>().getFolders();
                      context
                          .read<LinksFromSelectedFolderCubit>()
                          .getSelectedLinks(folder, 0);
                    }
                  });
                },
                child: LinkSlidAbleWidget(
                  index: index,
                  link: link,
                  child: buildBodyListItem(width, link),
                  callback: () {
                    LinkApi().deleteLink(link).then(
                      (result) {
                        if (result) {
                          showBottomToast(
                            context: context,
                            '링크가 삭제되었어요!',
                          );
                        }
                        totalLinks.clear();
                        foldersContext.read<GetFoldersCubit>().getFolders();
                        context
                            .read<LinksFromSelectedFolderCubit>()
                            .getSelectedLinks(folder, 0);
                      },
                    );
                  },
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider(
                height: 1,
                thickness: 1,
                color: greyTab,
                indent: 24,
                endIndent: 24,
              );
            },
          ),
        ),
      );
    }
  }

  Container buildBodyListItem(double width, Link link) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 115,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              width: (width - 24 * 2) - 159 - 20,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
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
                            height: 19 / 16,
                          ),
                        ),
                        const SizedBox(height: 7),
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
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
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
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(7),
              ),
              child: ColoredBox(
                color: grey100,
                child: link.image != null && link.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: link.image ?? '',
                        imageBuilder: (context, imageProvider) => Container(
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
                          return const SizedBox(
                            width: 159,
                            height: 116,
                          );
                        },
                      )
                    : const SizedBox(
                        width: 159,
                        height: 116,
                      ),
              ),
            ),
          )
        ],
      ),
    );
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
