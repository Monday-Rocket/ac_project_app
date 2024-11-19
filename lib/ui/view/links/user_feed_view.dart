// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/feed/feed_view_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_link_cubit.dart';
import 'package:ac_project_app/cubits/scroll/scroll_cubit.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/gen/fonts.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
import 'package:ac_project_app/ui/widget/user/user_info.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserFeedView extends StatelessWidget {
  const UserFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = getArguments(context);
    final user = args['user'] as DetailUser;
    final folders = args['folders'] as List<Folder>;
    final isMine = args['isMine'] as bool;
    final folderId = args['folderId'] as String?;

    // find index from folders by folderId
    final index =
        folders.indexWhere((element) => element.id.toString() == folderId);

    if (folders.isNotEmpty && index != -1) {
      // index가 처음이 되는 리스트로 folders를 재정렬
      folders.insert(0, folders.removeAt(index));
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => FeedViewCubit(folders)),
        BlocProvider(create: (_) => GetUserFoldersCubit()),
        BlocProvider(create: (_) => UploadLinkCubit()),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<FeedViewCubit, List<Link>>(
          builder: (feedContext, links) {
            final totalLinks = feedContext.watch<FeedViewCubit>().totalLinks;
            if (feedContext.read<FeedViewCubit>().hasRefresh) {
              totalLinks.clear();
              feedContext.read<FeedViewCubit>().hasRefresh = false;
            }

            return BlocProvider(
              create: (_) => ScrollCubit(
                feedContext.read<FeedViewCubit>().scrollController,
              ),
              child: BlocBuilder<ScrollCubit, bool>(
                builder: (scrollContext, isMove) {
                  return buildNotificationListener(
                    feedContext,
                    totalLinks,
                    context,
                    user,
                    isMine,
                    folders,
                    isMove,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  NotificationListener<ScrollEndNotification> buildNotificationListener(
    BuildContext feedContext,
    List<Link> totalLinks,
    BuildContext context,
    DetailUser user,
    bool isMine,
    List<Folder> folders,
    bool isMove,
  ) {
    Log.i('detailUser: ${user.toJson()}');
    return NotificationListener<ScrollEndNotification>(
      onNotification: (scrollEnd) {
        final metrics = scrollEnd.metrics;
        if (metrics.atEdge && metrics.pixels != 0) {
          feedContext.read<FeedViewCubit>().loadMore();
        }

        return true;
      },
      child: RefreshIndicator(
        onRefresh: () => refresh(feedContext, totalLinks),
        color: primary600,
        child: Stack(
          children: [
            Visibility(
              visible: !isMove,
              child: Assets.images.myFolderBack.image(
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fill,
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                controller: feedContext.read<FeedViewCubit>().scrollController,
                slivers: [
                  buildTopAppBar(context, user, isMine, isMove),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Image.asset(
                          ProfileImage.makeImagePath(user.profile_img),
                          width: 105.w,
                          height: 105.w,
                        ),
                        SizedBox(height: 6.w),
                        Text(
                          user.nickname,
                          style: TextStyle(
                            color: const Color(0xff0e0e0e),
                            fontWeight: FontWeight.bold,
                            fontSize: 28.sp,
                            letterSpacing: -0.6.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FolderNameListView(context, folders, feedContext.read<FeedViewCubit>().scrollController),
                  buildListBody(
                    context,
                    totalLinks,
                    user,
                    isMine,
                    feedContext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopAppBar(
    BuildContext context,
    DetailUser user,
    bool isMine,
    bool isMove,
  ) {
    return SliverAppBar(
      pinned: true,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: SvgPicture.asset(Assets.images.icBack, width: 24.w, height: 24.w, fit: BoxFit.cover,),
        color: grey900,
        padding: EdgeInsets.only(left: 20.w, right: 8.w),
      ),
      leadingWidth: 44.w,
      toolbarHeight: 48.w,
      actions: [
        if (!isMine)
          InkWell(
            onTap: () => showUserOptionDialog(
              context,
              user,
              callback: () {
                Navigator.pop(context);
              },
            ),
            child: Container(
              margin: EdgeInsets.only(right: 24.w),
              child: SvgPicture.asset(
                Assets.images.more,
                width: 25.w,
                height: 25.w,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: !isMove ? Colors.transparent : Colors.white,
        ),
      ),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  Widget FolderNameListView(
    BuildContext parentContext,
    List<Folder> folders,
    ScrollController scrollController,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        margin: EdgeInsets.only(top: 23.w, left: 12.w, right: 20.w),
        child: DefaultTabController(
          length: folders.length,
          child: SizedBox(
            height: 36.w,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 15.w,
                      right: 11.w,
                      bottom: 1.w,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            color: greyTab,
                            height: 1.w,
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
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: 100.w,
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: 7.w,
                            ),
                            child: Text(
                              folder.name ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }
                      return TabBar(
                        padding: EdgeInsets.zero,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        unselectedLabelColor: lightGrey700,
                        labelColor: primaryTab,
                        labelStyle: TextStyle(
                          fontFamily: FontFamily.pretendard,
                          fontSize: 16.sp,
                          height: 19 / 16,
                          fontWeight: FontWeight.w800,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontFamily: FontFamily.pretendard,
                          fontSize: 16.sp,
                          height: 19 / 16,
                          fontWeight: FontWeight.bold,
                        ),
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(
                            color: primaryTab,
                            width: 2.5.w,
                          ),
                        ),
                        tabs: tabs,
                        onTap: (index) {
                          final cubit = context.read<FeedViewCubit>();
                          cubit.totalLinks.clear();
                          cubit.selectFolder(index).then(
                                (value) => scrollController.jumpTo(0),
                              );
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

  Widget buildListBody(
    BuildContext parentContext,
    List<Link> totalLinks,
    DetailUser user,
    bool isMine,
    BuildContext feedContext,
  ) {
    final width = MediaQuery.of(parentContext).size.width;
    final height = MediaQuery.of(parentContext).size.height;

    return (totalLinks.isEmpty)
        ? SliverToBoxAdapter(
            child: Center(
              child: SizedBox(
                height: height / 2,
                child: Center(
                  child: Text(
                    emptyLinksString,
                    style: TextStyle(
                      color: grey300,
                      fontWeight: FontWeight.w500,
                      fontSize: 16.sp,
                      height: 19 / 16,
                    ),
                  ),
                ),
              ),
            ),
          )
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final link = totalLinks[index];
                return Column(
                  children: [
                    buildBodyListItem(
                      context,
                      link,
                      user,
                      isMine,
                      width,
                      totalLinks,
                      parentContext,
                    ),
                    if (index != totalLinks.length - 1)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Divider(
                          height: 1.w,
                          thickness: 1.w,
                          color: greyTab,
                        ),
                      ),
                  ],
                );
              },
              childCount: totalLinks.length,
            ),
          );
  }

  GestureDetector buildBodyListItem(
    BuildContext context,
    Link newLink,
    DetailUser user,
    bool isMine,
    double width,
    List<Link> totalLinks,
    BuildContext parentContext,
  ) {
    final link = newLink.copyWith(user: user);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.linkDetail,
          arguments: {
            'link': link,
          },
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: 20.w,
          horizontal: 24.w,
        ),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserInfoWidget(context: context, link: link),
            if (link.describe != null && (link.describe?.isNotEmpty ?? false))
              Column(
                children: [
                  SizedBox(
                    height: 17.w,
                  ),
                  Text(
                    link.describe ?? '',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: grey800,
                      height: 26 / 16,
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
            Container(
              margin: EdgeInsets.only(
                top: 16.w,
                bottom: 18.w,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(7.w),
                ),
                child: hasHttpImageUrl(link)
                    ? Container(
                        constraints: const BoxConstraints(
                          minWidth: double.infinity,
                        ),
                        color: grey100,
                        child: CachedNetworkImage(
                          imageUrl: link.image ?? '',
                          imageBuilder: (context, imageProvider) => Container(
                            height: 160.w,
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
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: width - (24 * 2 + 25 + 18).w,
                      child: Text(
                        link.title ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: blackBold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => isMine
                          ? showMyLinkOptionsDialog(
                              link,
                              context,
                              popCallback: () => refresh(
                                context,
                                totalLinks,
                              ),
                            )
                          : showLinkOptionsDialog(
                              link,
                              parentContext,
                              callback: () => Navigator.pop(context),
                            ),
                      child: SvgPicture.asset(
                        Assets.images.moreVert,
                        width: 25.w,
                        height: 25.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(right: 25.w),
                  child: Text(
                    link.url ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: grey500,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> refresh(BuildContext context, List<Link> totalLinks) async {
    totalLinks.clear();
    context.read<FeedViewCubit>().refresh();
  }
}
