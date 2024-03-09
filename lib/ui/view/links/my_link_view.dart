import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_selected_folder_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_folder_cubit.dart';
import 'package:ac_project_app/cubits/tool_tip/my_link_upload_tool_tip_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/gen/fonts.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/provider/tool_tip_check.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/buttons/upload_button.dart';
import 'package:ac_project_app/ui/widget/link_hero.dart';
import 'package:ac_project_app/ui/widget/scaffold_with_stack_widget.dart';
import 'package:ac_project_app/ui/widget/shape/reverse_triangle_painter.dart';
import 'package:ac_project_app/ui/widget/slidable/link_slidable_widget.dart';
import 'package:ac_project_app/ui/widget/widget_offset.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyLinkView extends StatelessWidget {
  MyLinkView({super.key});

  final toolTipKey = GlobalKey();

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
              BlocProvider(
                create: (_) => MyLinkUploadToolTipCubit(toolTipKey),
              ),
            ],
            child: BlocBuilder<GetSelectedFolderCubit, Folder>(
              builder: (context, folder) {
                return ScaffoldWithStackWidget(
                  scaffold: Scaffold(
                    backgroundColor: Colors.white,
                    body: SafeArea(
                      child: BlocBuilder<LinksFromSelectedFolderCubit,
                          LinkListState>(
                        builder: (cubitContext, state) {
                          return Stack(
                            children: [
                              NotificationListener<ScrollEndNotification>(
                                onNotification: (scrollEnd) {
                                  final metrics = scrollEnd.metrics;
                                  if (metrics.atEdge && metrics.pixels != 0) {
                                    context
                                        .read<LinksFromSelectedFolderCubit>()
                                        .loadMore();
                                  }
                                  return true;
                                },
                                child: CustomScrollView(
                                  //crossAxisAlignment: CrossAxisAlignment.start,
                                  slivers: [
                                    buildTopAppBar(context),
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
                              ),
                              FloatingUploadButton(
                                context,
                                callback: () {
                                  links.clear();
                                  context
                                      .read<LinksFromSelectedFolderCubit>()
                                      .refresh();
                                },
                              ),
                              if (state is LinkListLoadingState ||
                                  state is LinkListInitialState)
                                Center(
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 30.h),
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
                  ),
                  widget: BlocBuilder<MyLinkUploadToolTipCubit, WidgetOffset?>(
                    builder: (ctx, widgetOffset) {
                      if (widgetOffset == null) {
                        return const SizedBox.shrink();
                      } else {
                        if (widgetOffset.visible) {
                          Future.delayed(const Duration(seconds: 3), () {
                            ctx.read<MyLinkUploadToolTipCubit>().invisible();
                            ToolTipCheck.setMyLinkUploaded();
                          });
                        }
                        return AnimatedOpacity(
                          opacity: widgetOffset.visible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Stack(
                            children: [
                              Positioned(
                                left: widgetOffset.getTopMid().dx - 6.w,
                                top: widgetOffset.rightBottom.dy + 4.h,
                                child: CustomPaint(
                                  painter: ReverseTrianglePainter(
                                    strokeColor: grey900,
                                    strokeWidth: 1,
                                    paintingStyle: PaintingStyle.fill,
                                  ),
                                  child: SizedBox(
                                    width: 12.w,
                                    height: 8.h,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 14.w,
                                top: widgetOffset.rightBottom.dy + 12.h,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4.r)),
                                    color: grey900,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 10.h,
                                  ),
                                  child: Center(
                                    child: DefaultTextStyle(
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0,
                                      ),
                                      child: const Text(
                                        '폴더에 링크를 바로 업로드 해보세요!',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildTopAppBar(
    BuildContext context,
  ) {
    return SliverAppBar(
      pinned: true,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: SvgPicture.asset(Assets.images.icBack),
        color: grey900,
        padding: EdgeInsets.only(left: 20.w, right: 8.w),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  Widget buildTitleBar(Folder folder) {
    final classified = folder.isClassified ?? true;
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(left: 24.w, right: 12.w, top: 10.h),
        child: Row(
          children: [
            Text(
              classified ? folder.name! : '미분류',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30.sp,
                height: (36 / 30).h,
              ),
            ),
            if (!(folder.visible ?? false))
              Container(
                margin: EdgeInsets.only(left: 8.w),
                child: Assets.images.icLockPng.image(),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget buildContentsCountText(BuildContext context) {
    final count = context.read<LinksFromSelectedFolderCubit>().totalCount;
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(left: 24.w, top: 3.h),
        child: Text(
          '콘텐츠 ${addCommasFrom(count)}개',
          style: TextStyle(
            color: greyText,
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar(BuildContext context, List<Link> totalLinks) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(top: 23.h, left: 23.w, right: 23.w),
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
                  decoration: BoxDecoration(
                    color: ccGrey100,
                    borderRadius: BorderRadius.all(Radius.circular(7.r)),
                  ),
                  width: double.infinity,
                  height: 36.h,
                  margin: EdgeInsets.only(right: 6.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.w),
                      child: Assets.images.folderSearchIcon.image(),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () =>
                  Navigator.pushNamed(context, Routes.upload).then((_) {
                // update
                totalLinks.clear();
                ToolTipCheck.setMyLinkUploaded();
                context.read<GetFoldersCubit>().getFolders();
              }),
              child: Padding(
                padding: EdgeInsets.all(6.r),
                child: SizedBox(
                  key: toolTipKey,
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    Assets.images.btnAdd,
                  ),
                ),
              ),
            ),
          ],
        ),
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
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(top: 30.h, left: 12.w, right: 20.w),
        padding: EdgeInsets.only(bottom: 18.h),
        child: DefaultTabController(
          length: folders.length,
          initialIndex: tabIndex,
          child: SizedBox(
            height: 36.h,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 15.w,
                      right: 11.w,
                      bottom: 1.h,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            color: greyTab,
                            height: 1.h,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 7.w),
                  child: Builder(
                    builder: (context) {
                      final tabs = <Widget>[];
                      for (final folder in folders) {
                        tabs.add(
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 7.h,
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
                        tabAlignment: TabAlignment.start,
                        unselectedLabelColor: grey700,
                        labelColor: primaryTab,
                        labelStyle: TextStyle(
                          fontFamily: FontFamily.pretendard,
                          fontSize: 16.sp,
                          height: (19 / 16).h,
                          fontWeight: FontWeight.w800,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontFamily: FontFamily.pretendard,
                          fontSize: 16.sp,
                          height: (19 / 16).h,
                          fontWeight: FontWeight.bold,
                        ),
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(
                            color: primaryTab,
                            width: 2.5.w,
                          ),
                        ),
                        labelPadding: EdgeInsets.symmetric(horizontal: 13.w),
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
      return buildEmptyList(context);
    } else {
      if (state is LinkListLoadedState && folderState is FolderLoadedState) {
        final links = state.links;
        totalLinks.addAll(links);
      }
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final link = totalLinks[index];
            return Column(
              children: [
                buildLinkItem(
                  context,
                  link,
                  totalLinks,
                  foldersContext,
                  folder,
                  index,
                  width,
                ),
                if (index != totalLinks.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Divider(
                        height: 1.h,
                        thickness: 1.h,
                        color: greyTab,
                        indent: 24.w,
                        endIndent: 24.w,
                      ),
                    ),
                  ),
              ],
            );
          },
          childCount: totalLinks.length,
        ),
      );
    }
  }

  InkWell buildLinkItem(
    BuildContext context,
    Link link,
    List<Link> totalLinks,
    BuildContext foldersContext,
    Folder folder,
    int index,
    double width,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.linkDetail,
          arguments: {
            'link': link,
            'isMine': true,
            'visible': folder.visible,
          },
        ).then((result) {
          Log.i(result);
          if (result == 'changed') {
            // update
            totalLinks.clear();

            foldersContext.read<GetFoldersCubit>().getFolders();
            context
                .read<LinksFromSelectedFolderCubit>()
                .getSelectedLinks(folder, 0);
          } else if (result == 'deleted') {
            Navigator.pop(context);
          }
        });
      },
      child: LinkSlidAbleWidget(
        index: index,
        link: link,
        child: buildBodyListItem(width, link),
        callback: () {
          getIt<LinkApi>().deleteLink(link).then(
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
  }

  Container buildBodyListItem(double width, Link link) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 18.h,
        horizontal: 24.w,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 115.h,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 5.h),
              width: width * (130 / 375),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: blackBold,
                            overflow: TextOverflow.ellipsis,
                            height: (19 / 16).h,
                          ),
                        ),
                        SizedBox(height: 7.h),
                        Text(
                          link.describe ?? '\n\n',
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 12.sp,
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
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFFC0C2C4),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: LinkHero(
              tag: 'linkImage${link.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(7.r),
                ),
                child: ColoredBox(
                  color: grey100,
                  child: link.image != null && link.image!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: link.image ?? '',
                          imageBuilder: (context, imageProvider) => Container(
                            width: 159.w,
                            height: 116.h,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) {
                            return SizedBox(
                              width: 159.w,
                              height: 116.h,
                            );
                          },
                        )
                      : SizedBox(
                          width: 159.w,
                          height: 116.h,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyList(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.width / 3),
        child: Center(
          child: Text(
            emptyLinksString,
            style: TextStyle(
              color: grey300,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
