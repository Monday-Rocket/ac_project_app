import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/home/get_job_list_cubit.dart';
import 'package:ac_project_app/cubits/home/topic_list_state.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_job_group_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/resource.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_dialog.dart';
import 'package:ac_project_app/util/list_utils.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetJobListCubit, JobListState>(
      builder: (jobContext, state) {
        if (state is LoadedState) {
          return SafeArea(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 24.w, right: 24.w, top: 20.h),
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
                buildJobListView(
                  jobContext,
                  state.jobs.sortMyJobs(profile.jobGroup!.id!),
                ),
                buildListBody(jobContext),
              ],
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget buildListBody(BuildContext parentContext) {
    final width = MediaQuery.of(parentContext).size.width;

    return BlocBuilder<LinksFromSelectedJobGroupCubit, List<Link>>(
      builder: (context, links) {
        final totalLinks = _setTotalLinks(context, links);
        if (totalLinks.isEmpty) {
          return Expanded(
            child: Center(
              child: Text(
                '등록된 링크가 없습니다',
                style: TextStyle(
                  color: grey300,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                  height: (19/16).h,
                ),
              ),
            ),
          );
        } else {
          return Expanded(
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (scrollNotification) {
                final metrics = scrollNotification.metrics;
                if (metrics.axisDirection != AxisDirection.down) return false;
                if (metrics.extentAfter <= 800) {
                  context.read<LinksFromSelectedJobGroupCubit>().loadMore();
                }
                return true;
              },
              child: RefreshIndicator(
                onRefresh: () => refresh(context, totalLinks),
                color: primary600,
                child: ListView.separated(
                  itemCount: totalLinks.length,
                  physics: const ClampingScrollPhysics(),
                  controller: context
                      .read<LinksFromSelectedJobGroupCubit>()
                      .scrollController,
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
                        margin: EdgeInsets.symmetric(
                          vertical: 20.h,
                          horizontal: 24.w,
                        ),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final profileState = context
                                    .read<GetProfileInfoCubit>()
                                    .state as ProfileLoadedState;
                                await Navigator.of(context).pushNamed(
                                  Routes.userFeed,
                                  arguments: {
                                    'user': link.user,
                                    'folders': await context
                                        .read<GetUserFoldersCubit>()
                                        .getFolders(link.user!.id!),
                                    'isMine':
                                    profileState.profile.id == link.user!.id,
                                  },
                                );
                              },
                              child: Row(
                                children: [
                                  Image.asset(
                                    makeImagePath(link.user?.profileImg ?? '01'),
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
                                            link.user?.nickname ?? '',
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
                                              color: primary66_200,
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
                                                  link.user?.jobGroup?.name ?? '',
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
                            if (link.describe != null &&
                                (link.describe?.isNotEmpty ?? false))
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
                                    fadeInDuration:
                                    const Duration(milliseconds: 300),
                                    fadeOutDuration:
                                    const Duration(milliseconds: 300),
                                    imageBuilder:
                                        (context, imageProvider) =>
                                        Container(
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
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      width: width - (24 * 2 + 25),
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
                                      onTap: () {
                                        final profileState = context
                                            .read<GetProfileInfoCubit>()
                                            .state as ProfileLoadedState;
                                        if (profileState.profile.id ==
                                            link.user!.id) {
                                          showMyLinkOptionsDialog(
                                            link,
                                            context,
                                            popCallback: () => refresh(
                                              context,
                                              totalLinks,
                                            ),
                                          );
                                        } else {
                                          showLinkOptionsDialog(
                                            link,
                                            context,
                                            callback: () =>
                                                refresh(context, totalLinks),
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
                  },
                  separatorBuilder: (_, __) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Divider(height: 1.h, thickness: 1.w, color: ccGrey200),
                  ),
                ),
              ),
            ),
          );
        }
      },
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

  Widget buildJobListView(
    BuildContext jobContext,
    List<JobGroup> jobs,
  ) {
    return Container(
      margin: EdgeInsets.only(top: 23.h, left: 12.w, right: 20.w),
      child: DefaultTabController(
        length: jobs.length,
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
                    for (final job in jobs) {
                      tabs.add(
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 7.h,
                          ),
                          child: Text(
                            job.name ?? '',
                          ),
                        ),
                      );
                    }
                    return TabBar(
                      isScrollable: true,
                      unselectedLabelColor: grey700,
                      labelColor: primaryTab,
                      labelPadding: EdgeInsets.symmetric(horizontal: 13.w),
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
                        insets: EdgeInsets.symmetric(horizontal: 15.w),
                      ),
                      tabs: tabs,
                      onTap: (index) {
                        jobContext
                            .read<LinksFromSelectedJobGroupCubit>()
                            .hasLoadMore = false;
                        final selectedJobGroupId = jobs[index].id!;
                        jobContext
                            .read<LinksFromSelectedJobGroupCubit>()
                            .clear();
                        jobContext
                            .read<LinksFromSelectedJobGroupCubit>()
                            .getSelectedJobLinks(selectedJobGroupId, 0)
                            .then(
                              (value) => jobContext
                                  .read<LinksFromSelectedJobGroupCubit>()
                                  .scrollController
                                  .jumpTo(0),
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
    );
  }

  Future<void> refresh(BuildContext context, List<Link> totalLinks) async {
    context.read<LinksFromSelectedJobGroupCubit>().refresh();
  }
}
