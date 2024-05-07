import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/linkpool_pick/linkpool_pick_cubit.dart';
import 'package:ac_project_app/cubits/linkpool_pick/linkpool_pick_result_state.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_job_group_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/linkpool_pick/linkpool_pick.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
import 'package:ac_project_app/ui/widget/link_hero.dart';
import 'package:ac_project_app/ui/widget/user/user_info.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LinkpoolPickCubit, LinkpoolPickResultState>(
      builder: (pickContext, linkpoolPickState) {
        return BlocBuilder<GetProfileInfoCubit, ProfileState>(
          builder: (context, profileState) {
            if (profileState is ProfileLoadedState) {
              return SafeArea(
                child: NotificationListener<ScrollEndNotification>(
                  onNotification: (scrollNotification) {
                    final metrics = scrollNotification.metrics;
                    if (metrics.axisDirection != AxisDirection.down) {
                      return false;
                    }
                    if (metrics.extentAfter <= 800) {
                      context.read<GetLinksCubit>().loadMore();
                    }
                    return true;
                  },
                  child: RefreshIndicator(
                    onRefresh: () => refresh(context),
                    color: primary600,
                    child: CustomScrollView(
                      controller: context
                          .read<GetLinksCubit>()
                          .scrollController,
                      slivers: <Widget>[
                        SearchBar(context),
                        LinkpoolPickMenu(pickContext, linkpoolPickState),
                        buildListBody(pickContext),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        );
      },
    );
  }

  SliverToBoxAdapter SearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          top: 20.h,
        ),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            Routes.search,
            arguments: {
              'isMine': false,
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
                child: Assets.images.folderSearchIcon.image(
                  width: 24.w,
                  height: 24.h,
                ), // Image.asset(
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildListBody(BuildContext parentContext) {
    final width = MediaQuery.of(parentContext).size.width;
    final height = MediaQuery.of(parentContext).size.height;

    return BlocBuilder<GetLinksCubit, List<Link>>(
      builder: (context, links) {
        final totalLinks = _setTotalLinks(context, links);
        if (totalLinks.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: SizedBox(
                height: height * (3 / 4),
                child: Center(
                  child: Text(
                    emptyLinksString,
                    style: TextStyle(
                      color: grey300,
                      fontWeight: FontWeight.w500,
                      fontSize: 16.sp,
                      height: (19 / 16).h,
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final link = totalLinks[index];
                return Column(
                  children: [
                    BodyListItem(parentContext, link, width, totalLinks),
                    GreyDivider(index, totalLinks.length - 1),
                  ],
                );
              },
              childCount: totalLinks.length,
            ),
          );
        }
      },
    );
  }

  Widget GreyDivider(int index, int length) {
    if (index != length) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Divider(
          height: 1.h,
          thickness: 1.w,
          color: ccGrey200,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  GestureDetector BodyListItem(
    BuildContext context,
    Link link,
    double width,
    List<Link> totalLinks,
  ) {
    return GestureDetector(
      onTap: () {
        showLinkDetail(context, link);
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
            UserInfoWidget(
              context: context,
              link: link,
            ),
            if (link.describe != null && (link.describe?.isNotEmpty ?? false))
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
                      letterSpacing: -0.1,
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
              child: LinkHero(
                tag: 'linkImage${link.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.all(
                    Radius.circular(7.r),
                  ),
                  child: hasHttpImageUrl(link)
                      ? Container(
                          constraints: const BoxConstraints(
                            minWidth: double.infinity,
                          ),
                          color: grey100,
                          child: CachedNetworkImage(
                            imageUrl: link.image ?? '',
                            fadeInDuration: const Duration(milliseconds: 300),
                            fadeOutDuration: const Duration(milliseconds: 300),
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
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    LinkHero(
                      tag: 'linkTitle${link.id}',
                      child: SizedBox(
                        width: width - (24 * 2 + 30),
                        child: Text(
                          link.title ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: blackBold,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final profileState = context
                            .read<GetProfileInfoCubit>()
                            .state as ProfileLoadedState;
                        if (profileState.profile.id == link.user!.id) {
                          showMyLinkOptionsDialog(
                            link,
                            context,
                            popCallback: () => refresh(
                              context,
                            ),
                          );
                        } else {
                          showLinkOptionsDialog(
                            link,
                            context,
                            callback: () => refresh(context),
                          );
                        }
                      },
                      child: SvgPicture.asset(
                        Assets.images.moreVert,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Padding(
                  padding: EdgeInsets.only(right: 25.w),
                  child: LinkHero(
                    tag: 'linkUrl${link.id}',
                    child: Text(
                      link.url ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: grey500,
                        fontSize: 12.sp,
                        letterSpacing: -0.1,
                      ),
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

  void showLinkDetail(BuildContext context, Link link) {
    Navigator.pushNamed(
      context,
      Routes.linkDetail,
      arguments: {
        'link': link,
      },
    );
  }

  List<Link> _setTotalLinks(BuildContext context, List<Link> links) {
    final totalLinks =
        context.watch<GetLinksCubit>().totalLinks;
    if (context.read<GetLinksCubit>().hasRefresh) {
      totalLinks.clear();
      context.read<GetLinksCubit>().hasRefresh = false;
    }
    totalLinks.addAll(links);
    return totalLinks;
  }

  void addLinks(BuildContext context, List<Link> totalLinks, List<Link> links) {
    if (context.read<GetLinksCubit>().hasRefresh) {
      totalLinks.clear();
      context.read<GetLinksCubit>().hasRefresh = false;
    }
    totalLinks.addAll(links);
  }

  Future<void> refresh(BuildContext context) async {
    context.read<GetLinksCubit>().refresh();
  }

  Widget LinkpoolPickMenu(BuildContext context, LinkpoolPickResultState state) {
    Log.i('state: $state');
    if (state is! LinkpoolPickResultLoadedState) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final linkpoolPicks = state.linkpoolPicks;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: 30.h, left: 12.w, bottom: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 13.w, bottom: 16.h),
              child: Text(
                'LINKPOOL PICK',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  for (final pick in linkpoolPicks)
                    Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: LinkpoolPickItem(context, pick),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget LinkpoolPickItem(BuildContext context, LinkpoolPick pick) {
    final width = MediaQuery.of(context).size.width;

    final color = pick.getColor();
    return GestureDetector(
      onTap: () async {
        final result = await context
            .read<LinkpoolPickCubit>()
            .getLinkpoolPickLink(pick.linkId);
        result.when(
          success: (link) {
            showLinkDetail(context, link);
          },
          error: (msg) {},
        );
      },
      child: Container(
        width: width - 60.w,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.all(Radius.circular(6.r)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 12.h, left: 10.w, bottom: 12.h),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 92.w,
                      height: 90.w,
                      color: Colors.transparent,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 6.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(4.r)),
                      child: CachedNetworkImage(
                        imageUrl: pick.image,
                        width: 86.h,
                        height: 86.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Container(
                      padding: EdgeInsets.only(
                        top: 3.h,
                        bottom: 2.h,
                        left: 6.w,
                        right: 6.w,
                      ),
                      decoration: BoxDecoration(
                        color: grey900,
                        borderRadius: BorderRadius.all(Radius.circular(3.r)),
                      ),
                      child: Text(
                        'PICK',
                        style: TextStyle(
                          fontSize: 8.4.sp,
                          letterSpacing: -0.17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            10.horizontalSpace,
            Padding(
              padding: EdgeInsets.only(top: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      pick.getPerfectTitle(),
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: grey900,
                        letterSpacing: -0.17,
                        height: 21/16,
                      ),
                    ),
                  ),
                  3.verticalSpace,
                  Text(
                    pick.describe,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: grey600,
                      letterSpacing: -0.17,
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
}
