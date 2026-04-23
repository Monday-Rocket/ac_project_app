import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/get_selected_folder_cubit.dart';
import 'package:ac_project_app/cubits/folders/local_folders_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/cubits/links/local_links_from_folder_cubit.dart';
import 'package:ac_project_app/cubits/tool_tip/my_link_upload_tool_tip_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/provider/tool_tip_check.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/folder/show_create_folder_sheet.dart';
import 'package:ac_project_app/ui/widget/buttons/upload_button.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
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
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyLinkView extends StatelessWidget {
  MyLinkView({super.key});

  final toolTipKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final arguments = getArguments(context);
    final folders = arguments['folders'] as List<Folder>;
    final tabIndex = arguments['tabIndex'] as int;
    final selectedFolder = arguments['selectedFolder'] as Folder;
    final width = MediaQuery.of(context).size.width;
    final links = <Link>[];

    return BlocProvider(
      create: (_) => LocalFoldersCubit(),
      child: BlocBuilder<LocalFoldersCubit, FoldersState>(
        builder: (foldersContext, folderState) {
          if (folderState is FolderLoadedState) {
            folders
              ..clear()
              ..addAll(folderState.folders);
          }

          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => GetSelectedFolderCubit(selectedFolder),
              ),
              BlocProvider(
                create: (_) => LocalLinksFromFolderCubit(selectedFolder, 0),
              ),
              BlocProvider(
                create: (_) => MyLinkUploadToolTipCubit(toolTipKey),
              ),
            ],
            child: BlocBuilder<GetSelectedFolderCubit, Folder>(
              builder: (context, folder) {
                return ScaffoldWithStackWidget(
                  scaffold: LinkView(
                    context,
                    folders,
                    folder,
                    links,
                    tabIndex,
                    width,
                    folderState,
                    foldersContext,
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
                                top: widgetOffset.rightBottom.dy + 4.w,
                                child: CustomPaint(
                                  painter: ReverseTrianglePainter(
                                    strokeColor: grey900,
                                    strokeWidth: 1,
                                    paintingStyle: PaintingStyle.fill,
                                  ),
                                  child: SizedBox(
                                    width: 12.w,
                                    height: 8.w,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 14.w,
                                top: widgetOffset.rightBottom.dy + 12.w,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(4.w)),
                                    color: grey900,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 10.w,
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

  Scaffold LinkView(
    BuildContext context,
    List<Folder> folders,
    Folder folder,
    List<Link> links,
    int tabIndex,
    double width,
    FoldersState folderState,
    BuildContext foldersContext,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<LocalLinksFromFolderCubit, LinkListState>(
          builder: (cubitContext, state) {
            return Stack(
              children: [
                NotificationListener<ScrollEndNotification>(
                  onNotification: (scrollEnd) {
                    final metrics = scrollEnd.metrics;
                    if (metrics.atEdge && metrics.pixels > 100) {
                      context.read<LocalLinksFromFolderCubit>().loadMore();
                    }
                    return true;
                  },
                  child: CustomScrollView(
                    slivers: [
                      buildTopAppBar(context, folders, folder),
                      buildBreadcrumb(context, state),
                      buildTitleBar(folder),
                      LinkCountText(state, folder),
                      buildSearchBar(context, links),
                      SliverToBoxAdapter(child: SizedBox(height: 18.w)),
                      buildChildFoldersSection(context, folders, state, folder),
                      buildBodyList(
                        folder: folder,
                        width: width,
                        cubitContext: cubitContext,
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
                    context.read<LocalLinksFromFolderCubit>().refresh();
                  },
                ),
                if (state is LinkListLoadingState || state is LinkListInitialState)
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(bottom: 30.w),
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
  }

  Widget buildTopAppBar(
    BuildContext context,
    List<Folder> folders,
    Folder folder,
  ) {
    final actions = <Widget>[];
    if (folder.isClassified != false) {
      actions.add(
        InkWell(
          onTap: () {
            showFolderOptionsDialog(
              folders,
              folder,
              context,
              fromLinkView: true,
            );
          },
          child: Container(
            margin: EdgeInsets.only(right: 20.w),
            padding: EdgeInsets.all(4.w),
            child: SvgPicture.asset(
              Assets.images.more,
              width: 25.w,
              height: 25.w,
            ),
          ),
        ),
      );
    }
    return SliverAppBar(
      pinned: true,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: SvgPicture.asset(
          Assets.images.icBack,
          width: 24.w,
          height: 24.w,
          fit: BoxFit.cover,
        ),
        color: grey900,
        padding: EdgeInsets.only(left: 20.w, right: 8.w),
      ),
      leadingWidth: 44.w,
      toolbarHeight: 48.w,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
        ),
      ),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  Widget buildTitleBar(Folder folder) {
    final classified = folder.isClassified ?? true;
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(left: 24.w, right: 12.w, top: 10.w),
        child: Row(
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: 250.w,
              ),
              child: Text(
                classified ? folder.name! : '미분류',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30.sp,
                  height: 36 / 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget LinkCountText(LinkListState state, Folder folder) {
    final count = (state is LinkListLoadedState) ? state.totalCount : 0;
    return buildContentsCountText(count);
  }

  Widget buildContentsCountText(int count) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(left: 24.w, top: 3.w),
        child: Text(
          '링크 ${addCommasFrom(count)}개',
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
        margin: EdgeInsets.only(top: 23.w, left: 23.w, right: 23.w),
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
                    borderRadius: BorderRadius.all(Radius.circular(7.w)),
                  ),
                  width: double.infinity,
                  height: 36.w,
                  margin: EdgeInsets.only(right: 6.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.w),
                      child: Assets.images.folderSearchIcon.image(
                        width: 18.w,
                        height: 18.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () => Navigator.pushNamed(context, Routes.upload).then((_) {
                // update
                totalLinks.clear();
                ToolTipCheck.setMyLinkUploaded();
                context.read<LocalFoldersCubit>().getFolders();
              }),
              child: Padding(
                padding: EdgeInsets.all(6.w),
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

  Widget buildBreadcrumb(BuildContext context, LinkListState state) {
    if (state is! LinkListLoadedState || state.breadcrumb.length < 2) {
      // 루트이거나(= 자기 자신 1개), 미분류(빈 리스트) 이면 노출 불필요
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final breadcrumb = state.breadcrumb;
    return SliverToBoxAdapter(
      child: Container(
        color: grey100,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.w),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < breadcrumb.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16.sp,
                      color: grey600,
                    ),
                  ),
                InkWell(
                  onTap: i == breadcrumb.length - 1
                      ? null
                      : () => _jumpToFolder(context, breadcrumb[i]),
                  child: Text(
                    breadcrumb[i].name ?? '',
                    style: TextStyle(
                      color: i == breadcrumb.length - 1 ? blackBold : grey600,
                      fontSize: 13.sp,
                      fontWeight: i == breadcrumb.length - 1
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildChildFoldersSection(
    BuildContext context,
    List<Folder> folders,
    LinkListState state,
    Folder currentFolder,
  ) {
    if (state is! LinkListLoadedState) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (currentFolder.isClassified == false) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final children = state.childFolders;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(bottom: 8.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChildFoldersHeader(context, currentFolder, children.length),
            if (children.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.w),
                child: Text(
                  '하위 폴더 없음',
                  style: TextStyle(color: grey400, fontSize: 13.sp),
                ),
              )
            else
              for (final child in children)
                InkWell(
                  onTap: () => _jumpToFolder(context, child),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.w,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: primary100,
                            borderRadius: BorderRadius.circular(10.w),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.folder,
                            size: 20.sp,
                            color: primary600,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                child.name ?? '',
                                style: TextStyle(
                                  color: blackBold,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.w),
                              Text(
                                '링크 ${addCommasFrom(child.linksTotal ?? child.links ?? 0)}개',
                                style: TextStyle(
                                  color: greyText,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: grey600,
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ),
                ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.w),
              child: Divider(height: 1, thickness: 1.w, color: greyTab),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildFoldersHeader(
    BuildContext context,
    Folder currentFolder,
    int childCount,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.w, 12.w, 8.w),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '하위 폴더 ($childCount)',
              style: TextStyle(
                color: grey600,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          InkWell(
            key: const Key('my_link_view_add_child_folder'),
            onTap: () => _onAddChildFolder(context, currentFolder),
            borderRadius: BorderRadius.circular(8.w),
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.create_new_folder_outlined,
                size: 18.sp,
                color: primary600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddChildFolder(
    BuildContext context,
    Folder parent,
  ) async {
    final newId = await showCreateFolderSheet(
      context,
      initialParentId: parent.id,
    );
    if (newId == null || !context.mounted) return;
    showBottomToast(
      context: context,
      "'${parent.name ?? ''}' 아래에 폴더가 생성되었어요!",
    );
    context.read<LocalLinksFromFolderCubit>().refresh();
    context.read<LocalFoldersCubit>().getFolders();
  }

  void _jumpToFolder(BuildContext context, Folder folder) {
    Navigator.pushReplacementNamed(
      context,
      Routes.myLinks,
      arguments: {
        'folders': [folder],
        'selectedFolder': folder,
        'tabIndex': 0,
      },
    );
  }

  Widget buildBodyList({
    required Folder folder,
    required double width,
    required BuildContext cubitContext,
    required List<Link> totalLinks,
    required LinkListState state,
    required FoldersState folderState,
    required BuildContext foldersContext,
  }) {
    if (folder.links == 0) {
      return buildEmptyList(cubitContext);
    } else {
      Log.i(state);
      Log.i(folderState);
      if (state is LinkListLoadedState && folderState is FolderLoadedState) {
        final links = state.links;
        totalLinks.addAll(links);
      }
      Log.i(totalLinks);
      return SlidableAutoCloseBehavior(
        child: SliverList(
          delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
              final link = totalLinks[index];
              return Column(
                children: [
                  buildLinkItem(
                    cubitContext,
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
                          height: 1.w,
                          thickness: 1.w,
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
        ),
      );
    }
  }

  InkWell buildLinkItem(
    BuildContext cubitContext,
    Link link,
    List<Link> totalLinks,
    BuildContext foldersContext,
    Folder folder,
    int index,
    double width,
  ) {
    Log.i('build Link Item');
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          cubitContext,
          Routes.linkDetail,
          arguments: {
            'link': link,
            'isMine': true,
            'heroPrefix': 'myLink_',
          },
        ).then((result) {
          Log.i(result);
          if (result == 'changed') {
            // update
            totalLinks.clear();

            foldersContext.read<LocalFoldersCubit>().getFolders();
            cubitContext.read<LocalLinksFromFolderCubit>().refresh();
          } else if (result == 'deleted') {
            cubitContext.read<LocalLinksFromFolderCubit>().refresh();
          }
        });
      },
      child: LinkSlidAbleWidget(
        index: index,
        link: link,
        child: buildBodyListItem(width, link),
        callback: () {
          getIt<LocalLinkRepository>().deleteLink(link.id!).then(
            (count) {
              if (count > 0) {
                showBottomToast(
                  context: cubitContext,
                  '링크가 삭제되었어요!',
                );
              }
              totalLinks.clear();
              foldersContext.read<LocalFoldersCubit>().getFolders();
              cubitContext.read<LocalLinksFromFolderCubit>().getSelectedLinks(folder, 0);
            },
          );
        },
      ),
    );
  }

  Container buildBodyListItem(double width, Link link) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 18.w,
        horizontal: 24.w,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 115.w,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 5.w),
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
                            height: 19 / 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 7.w),
                        Text(
                          link.describe ?? '\n\n',
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: greyText,
                            overflow: TextOverflow.ellipsis,
                            letterSpacing: -0.1,
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
                        letterSpacing: -0.1,
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
              tag: 'myLink_linkImage${link.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(7.w),
                ),
                child: ColoredBox(
                  color: grey100,
                  child: link.image != null && link.image!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: link.image ?? '',
                          imageBuilder: (context, imageProvider) => Container(
                            width: 159.w,
                            height: 116.w,
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
                              height: 116.w,
                            );
                          },
                        )
                      : SizedBox(
                          width: 159.w,
                          height: 116.w,
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
