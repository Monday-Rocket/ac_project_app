import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/home/get_job_list_cubit.dart';
import 'package:ac_project_app/cubits/home/topic_list_state.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_job_group_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
import 'package:ac_project_app/ui/widget/link_hero.dart';
import 'package:ac_project_app/ui/widget/user/user_info.dart';
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
    return BlocBuilder<GetProfileInfoCubit, ProfileState>(
      builder: (context, profileState) {
        return BlocBuilder<GetJobListCubit, JobListState>(
          builder: (jobContext, state) {
            if (state is LoadedState && profileState is ProfileLoadedState) {
              return SafeArea(
                child: NotificationListener<ScrollEndNotification>(
                  onNotification: (scrollNotification) {
                    final metrics = scrollNotification.metrics;
                    if (metrics.axisDirection != AxisDirection.down) {
                      return false;
                    }
                    if (metrics.extentAfter <= 800) {
                      context.read<LinksFromSelectedJobGroupCubit>().loadMore();
                    }
                    return true;
                  },
                  child: RefreshIndicator(
                    onRefresh: () => refresh(context),
                    color: primary600,
                    child: CustomScrollView(
                      controller: context
                          .read<LinksFromSelectedJobGroupCubit>()
                          .scrollController,
                      slivers: <Widget>[
                        SliverToBoxAdapter(
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
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(7.r)),
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
                        ),
                        buildListBody(jobContext),
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

  Widget buildListBody(BuildContext parentContext) {
    final width = MediaQuery.of(parentContext).size.width;
    final height = MediaQuery.of(parentContext).size.height;

    return BlocBuilder<LinksFromSelectedJobGroupCubit, List<Link>>(
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
                    buildBodyListItem(context, link, width, totalLinks),
                    if (index != totalLinks.length - 1)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Divider(
                          height: 1.h,
                          thickness: 1.w,
                          color: ccGrey200,
                        ),
                      ),
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

  GestureDetector buildBodyListItem(
    BuildContext context,
    Link link,
    double width,
    List<Link> totalLinks,
  ) {
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

  List<Link> _setTotalLinks(BuildContext context, List<Link> links) {
    final totalLinks =
        context.watch<LinksFromSelectedJobGroupCubit>().totalLinks;
    if (context.read<LinksFromSelectedJobGroupCubit>().hasRefresh) {
      totalLinks.clear();
      context.read<LinksFromSelectedJobGroupCubit>().hasRefresh = false;
    }
    totalLinks.addAll(links);
    return totalLinks;
  }

  void addLinks(BuildContext context, List<Link> totalLinks, List<Link> links) {
    if (context.read<LinksFromSelectedJobGroupCubit>().hasRefresh) {
      totalLinks.clear();
      context.read<LinksFromSelectedJobGroupCubit>().hasRefresh = false;
    }
    totalLinks.addAll(links);
  }

  Future<void> refresh(BuildContext context) async {
    context.read<LinksFromSelectedJobGroupCubit>().refresh();
  }
}
