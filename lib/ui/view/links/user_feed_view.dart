// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/feed/feed_view_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/resource.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_dialog.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserFeedView extends StatefulWidget {
  UserFeedView({super.key});

  @override
  State<UserFeedView> createState() => _UserFeedViewState();
}

class _UserFeedViewState extends State<UserFeedView> {
  bool showBackground = false;

  @override
  Widget build(BuildContext context) {
    final args = getArguments(context);
    final user = args['user'] as DetailUser;
    final folders = args['folders'] as List<Folder>;
    final isMine = args['isMine'] as bool;

    return MultiBlocProvider(
      providers: [
        BlocProvider<FeedViewCubit>(
          create: (_) => FeedViewCubit(folders),
        ),
        BlocProvider<GetUserFoldersCubit>(
          create: (_) => GetUserFoldersCubit(),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Visibility(
              visible: !showBackground,
              child: Assets.images.myFolderBack.image(
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fill,
              ),
            ),
            SafeArea(
              child: BlocBuilder<FeedViewCubit, List<Link>>(
                builder: (feedContext, links) {
                  final totalLinks =
                      feedContext.watch<FeedViewCubit>().totalLinks;
                  if (feedContext.read<FeedViewCubit>().hasRefresh) {
                    totalLinks.clear();
                    feedContext.read<FeedViewCubit>().hasRefresh = false;
                  }
                  void scrollListener() {
                    if (feedContext
                            .read<FeedViewCubit>()
                            .scrollController
                            .offset >
                        5.h) {
                      setState(() {
                        showBackground = true;
                      });
                    } else {
                      setState(() {
                        showBackground = false;
                      });
                    }
                  }

                  feedContext
                      .read<FeedViewCubit>()
                      .scrollController
                      .addListener(scrollListener);

                  totalLinks.addAll(links);
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
                      child: CustomScrollView(
                        controller:
                            feedContext.read<FeedViewCubit>().scrollController,
                        slivers: [
                          buildTopAppBar(context, user, isMine),
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                Image.asset(
                                  makeImagePath(user.profileImg),
                                  width: 105.w,
                                  height: 105.h,
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  user.nickname,
                                  style: TextStyle(
                                    color: const Color(0xff0e0e0e),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28.sp,
                                    letterSpacing: -0.6.w,
                                  ),
                                )
                              ],
                            ),
                          ),
                          buildJobListView(context, folders),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopAppBar(BuildContext context, DetailUser user, bool isMine) {
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
                height: 25.h,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
      backgroundColor: !showBackground ? Colors.transparent : Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      elevation: 0,
    );
  }

  Widget buildJobListView(
    BuildContext parentContext,
    List<Folder> folders,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        margin: EdgeInsets.only(top: 23.h, left: 12.w, right: 20.w),
        child: DefaultTabController(
          length: folders.length,
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
                        unselectedLabelColor: lightGrey700,
                        labelColor: primaryTab,
                        labelStyle: TextStyle(
                          fontFamily: R_Font.PRETENDARD,
                          fontSize: 16.sp,
                          height: (19 / 16).h,
                          fontWeight: FontWeight.w800,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontFamily: R_Font.PRETENDARD,
                          fontSize: 16.sp,
                          height: (19 / 16).h,
                          fontWeight: FontWeight.bold,
                        ),
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(
                            color: primaryTab,
                            width: 2.5.w,
                          ),
                          insets: EdgeInsets.only(
                            left: 15.w,
                            right: 15.w,
                          ),
                        ),
                        tabs: tabs,
                        onTap: (index) {
                          final cubit = context.read<FeedViewCubit>();
                          cubit.totalLinks.clear();
                          cubit.selectFolder(index).then(
                              (value) => cubit.scrollController.jumpTo(0));
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
    return (totalLinks.isEmpty)
        ? SliverToBoxAdapter(
            child: Center(
              child: Text(
                '등록된 링크가 없습니다',
                style: TextStyle(
                  color: grey300,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                  height: (19 / 16).h,
                ),
              ),
            ),
          )
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                if (index.isEven) {
                  final link = totalLinks[index];
                  return buildBodyListItem(
                    context,
                    link,
                    user,
                    isMine,
                    width,
                    totalLinks,
                    parentContext,
                  );
                }
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Divider(height: 1.h, thickness: 1.h, color: greyTab),
                  ),
                );
              },
              childCount: totalLinks.length,
            ),
          );
  }

  GestureDetector buildBodyListItem(
      BuildContext context,
      Link link,
      DetailUser user,
      bool isMine,
      double width,
      List<Link> totalLinks,
      BuildContext parentContext) {
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
          vertical: 20.h,
          horizontal: 24.w,
        ),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async => Navigator.of(context).pushNamed(
                Routes.userFeed,
                arguments: {
                  'user': user,
                  'folders': await context
                      .read<GetUserFoldersCubit>()
                      .getFolders(user.id!),
                  'isMine': isMine,
                },
              ),
              child: Row(
                children: [
                  Image.asset(
                    makeImagePath(user.profileImg),
                    width: 32.w,
                    height: 32.h,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 32.w,
                        height: 32.h,
                        decoration: const BoxDecoration(
                          color: grey300,
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: 8.w,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.nickname,
                            style: const TextStyle(
                              color: grey900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(
                              left: 4.w,
                            ),
                            decoration: BoxDecoration(
                              color: primary200,
                              borderRadius: BorderRadius.all(
                                Radius.circular(4.r),
                              ),
                            ),
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 3.h,
                                  horizontal: 4.w,
                                ),
                                child: Text(
                                  user.jobGroup?.name ?? '',
                                  style: TextStyle(
                                    color: primary600,
                                    fontSize: 10.sp,
                                    letterSpacing: -0.2.w,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 4.h),
                        child: Text(
                          makeLinkTimeString(link.time ?? ''),
                          style: TextStyle(
                            color: grey400,
                            fontSize: 12.sp,
                            letterSpacing: -0.2.w,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            if (link.describe != null || (link.describe?.isNotEmpty ?? false))
              Column(
                children: [
                  SizedBox(
                    height: 17.h,
                  ),
                  Text(
                    link.describe ?? '',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: grey800,
                      height: (26 / 16).h,
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
            Container(
              margin: EdgeInsets.only(
                top: 16.h,
                bottom: 18.h,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(7.r),
                ),
                child: isLinkVerified(link)
                    ? Container(
                        constraints: const BoxConstraints(
                          minWidth: double.infinity,
                        ),
                        color: grey100,
                        child: CachedNetworkImage(
                          imageUrl: link.image ?? '',
                          imageBuilder: (context, imageProvider) => Container(
                            height: 160.h,
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
                      width: (width - (24 * 2 + 25)).w,
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
                      ),
                    ),
                  ],
                ),
                Text(
                  link.url ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: grey500,
                    fontSize: 12.sp,
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
