import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_folder_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
import 'package:ac_project_app/ui/widget/dialog/center_dialog.dart';
import 'package:ac_project_app/ui/widget/link_hero.dart';
import 'package:ac_project_app/ui/widget/slidable/link_slidable_widget.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';

class ShareLinkView extends StatelessWidget {
  const ShareLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = getArguments(context);
    final folder = arguments['folder'] as Folder;
    final isAdmin = arguments['isAdmin'] as bool;

    return BlocProvider(
      create: (_) => LinksFromSelectedFolderCubit(folder, 0),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocBuilder<LinksFromSelectedFolderCubit, LinkListState>(
            builder: (cubitContext, state) {
              return Stack(
                children: [
                  NotificationListener<ScrollEndNotification>(
                    onNotification: (scrollEnd) {
                      final metrics = scrollEnd.metrics;
                      if (metrics.atEdge && metrics.pixels != 0) {
                        context.read<LinksFromSelectedFolderCubit>().loadMore();
                      }
                      return true;
                    },
                    child: CustomScrollView(
                      slivers: [
                        buildTopAppBar(context, folder, isAdmin),
                        buildTitleBar(folder),
                        buildContentsCountText(state, folder.membersCount),
                        // buildSearchBar(),
                        buildBodyList(
                          folder: folder,
                          width: MediaQuery.of(context).size.width,
                          context: context,
                          totalLinks: [],
                          state: state,
                          foldersContext: context,
                        )
                      ],
                    ),
                  )
                ],
              );
            },
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
    required BuildContext foldersContext,
  }) {
    if (folder.links == 0) {
      return buildEmptyList(context);
    } else {
      if (state is LinkListLoadedState) {
        final links = state.links;
        totalLinks.addAll(links);
      }
      return SlidableAutoCloseBehavior(
        child: SliverList(
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
            context.read<LinksFromSelectedFolderCubit>().getSelectedLinks(folder, 0);
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
          getIt<LinkApi>().deleteLink(link).then((result) {
            if (result) {
              showBottomToast(
                context: context,
                '링크가 삭제되었어요!',
              );
            }
            totalLinks.clear();
            foldersContext.read<GetFoldersCubit>().getFolders();
            context.read<LinksFromSelectedFolderCubit>().getSelectedLinks(folder, 0);
          });
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
              tag: 'linkImage${link.id}',
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

  Widget buildContentsCountText(LinkListState state, int? membersCount) {
    final count = (state is LinkListLoadedState) ? state.totalCount : 0;
    final members = membersCount ?? 0;
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(left: 24.w, top: 3.w),
        child: Row(
          children: [
            Text(
              '링크 ${addCommasFrom(count)}개',
              style: TextStyle(
                color: greyText,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
            8.horizontalSpace,
            Container(
              width: 1,
              height: 10,
              color: grey300,
            ),
            8.horizontalSpace,
            Text(
              '$members명의 멤버',
              style: TextStyle(
                color: greyText,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
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
            if (!(folder.visible ?? false))
              Container(
                margin: EdgeInsets.only(left: 8.w),
                child: Assets.images.icLockWebp.image(width: 24.w, height: 24.w, fit: BoxFit.cover),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget buildTopAppBar(
    BuildContext context,
    Folder folder,
    bool isAdmin,
  ) {
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
      actions: [
        InkWell(
          onTap: () {
            showInviteDialog(context);
          },
          child: Container(
            padding: EdgeInsets.all(4.w),
            child: SvgPicture.asset(
              Assets.images.inviteUser,
              width: 24.w,
              height: 24.w,
            ),
          ),
        ),
        InkWell(
          onTap: () {
            showSharedFolderOptionsDialog(context, isAdmin: isAdmin);
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
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
        ),
      ),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  Widget buildSearchBar() {
    return Container();
  }
}
