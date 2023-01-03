// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/feed/feed_view_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
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
import 'package:flutter_svg/flutter_svg.dart';

class UserFeedView extends StatelessWidget {
  const UserFeedView({super.key});

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
            Image.asset(
              'assets/images/my_folder_back.png',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fill,
            ),
            SafeArea(
              child: Column(
                children: [
                  buildTopAppBar(context, user, isMine),
                  Column(
                    children: [
                      Image.asset(
                        makeImagePath(user.profileImg),
                        width: 105,
                        height: 105,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.nickname,
                        style: const TextStyle(
                          color: Color(0xff0e0e0e),
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          letterSpacing: -0.6,
                        ),
                      )
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        buildJobListView(context, folders),
                        BlocBuilder<FeedViewCubit, List<Link>>(
                          builder: (feedContext, links) {
                            final totalLinks =
                                feedContext.watch<FeedViewCubit>().totalLinks;
                            if (feedContext.read<FeedViewCubit>().hasRefresh) {
                              totalLinks.clear();
                              feedContext.read<FeedViewCubit>().hasRefresh =
                                  false;
                            }
                            totalLinks.addAll(links);

                            return buildListBody(
                              context,
                              totalLinks,
                              user,
                              isMine,
                              feedContext,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopAppBar(BuildContext context, DetailUser user, bool isMine) {
    return AppBar(
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: SvgPicture.asset('assets/images/ic_back.svg'),
        color: grey900,
        padding: const EdgeInsets.only(left: 20, right: 8),
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
              margin: const EdgeInsets.only(right: 24),
              child: SvgPicture.asset(
                'assets/images/more.svg',
                width: 25,
                height: 25,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      elevation: 0,
    );
  }

  Widget buildJobListView(
    BuildContext parentContext,
    List<Folder> folders,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 30 - 7, left: 12, right: 20),
      child: DefaultTabController(
        length: folders.length,
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
                        final cubit = context.read<FeedViewCubit>();
                        cubit.totalLinks.clear();
                        cubit.selectFolder(index).then((value) => cubit.scrollController.jumpTo(0));
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

  Widget buildListBody(
    BuildContext parentContext,
    List<Link> totalLinks,
    DetailUser user,
    bool isMine,
    BuildContext feedContext,
  ) {
    final width = MediaQuery.of(parentContext).size.width;
    return Builder(
      builder: (context) {
        return Expanded(
          child: NotificationListener<ScrollEndNotification>(
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
              child: ListView.separated(
                itemCount: totalLinks.length,
                physics: const AlwaysScrollableScrollPhysics(),
                controller: feedContext.read<FeedViewCubit>().scrollController,
                itemBuilder: (_, i) {
                  final link = totalLinks[i];
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
                      margin: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
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
                                  width: 32,
                                  height: 32,
                                  errorBuilder: (_, __, ___) {
                                    return Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: grey300,
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(
                                  width: 8,
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
                                          margin: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: primary200,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(4),
                                            ),
                                          ),
                                          child: Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 3,
                                                horizontal: 4,
                                              ),
                                              child: Text(
                                                user.jobGroup?.name ?? '',
                                                style: const TextStyle(
                                                  color: primary600,
                                                  fontSize: 10,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        makeLinkTimeString(link.time ?? ''),
                                        style: const TextStyle(
                                          color: grey400,
                                          fontSize: 12,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          if (link.describe != null ||
                              (link.describe?.isNotEmpty ?? false))
                            Column(
                              children: [
                                const SizedBox(
                                  height: 17,
                                ),
                                Text(
                                  link.describe ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: grey800,
                                    height: 26 / 16,
                                  ),
                                ),
                              ],
                            )
                          else
                            const SizedBox.shrink(),
                          Container(
                            margin: const EdgeInsets.only(
                              top: 16,
                              bottom: 18,
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(7),
                              ),
                              child: isLinkVerified(link)
                                  ? Container(
                                      constraints: const BoxConstraints(
                                        minWidth: double.infinity,
                                      ),
                                      color: grey100,
                                      child: CachedNetworkImage(
                                        imageUrl: link.image ?? '',
                                        imageBuilder:
                                            (context, imageProvider) =>
                                                Container(
                                          height: 160,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: width - (24 * 2 + 25),
                                    child: Text(
                                      link.title ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: blackBold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
                                            callback: () =>
                                                Navigator.pop(context),
                                          ),
                                    child: SvgPicture.asset(
                                      'assets/images/more_vert.svg',
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                link.url ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: grey500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(height: 1, color: grey900),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> refresh(BuildContext context, List<Link> totalLinks) async {
    totalLinks.clear();
    context.read<FeedViewCubit>().refresh();
  }
}
