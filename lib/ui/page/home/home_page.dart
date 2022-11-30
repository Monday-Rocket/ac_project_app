import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/home/get_job_list_cubit.dart';
import 'package:ac_project_app/cubits/home/topic_list_state.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_job_group_cubit.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/resource.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_dialog.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final totalLinks = <Link>[];
    return BlocBuilder<GetJobListCubit, JobListState>(
      builder: (jobContext, state) {
        if (state is LoadedState) {
          return SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 24, right: 24, top: 20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: grey100,
                      borderRadius: BorderRadius.all(Radius.circular(7)),
                    ),
                    margin: const EdgeInsets.only(right: 6),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      cursorColor: grey800,
                      style: const TextStyle(
                        color: grey800,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        prefixIcon: Image.asset(
                          'assets/images/folder_search_icon.png',
                        ),
                      ),
                      onChanged: (value) {
                        // context.read<GetFoldersCubit>().filter(value);
                      },
                    ),
                  ),
                ),
                buildJobListView(jobContext, state.jobs, totalLinks),
                buildListBody(jobContext, totalLinks),
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

  Widget buildListBody(BuildContext parentContext, List<Link> totalLinks) {
    final width = MediaQuery.of(parentContext).size.width;
    return BlocBuilder<LinksFromSelectedJobGroupCubit, List<Link>>(
      builder: (context, links) {
        totalLinks.addAll(links);
        return Expanded(
          child: NotificationListener<ScrollEndNotification>(
            onNotification: (scrollEnd) {
              final metrics = scrollEnd.metrics;
              if (metrics.atEdge && metrics.pixels != 0) {
                context.read<LinksFromSelectedJobGroupCubit>().loadMore();
              }
              return true;
            },
            child: RefreshIndicator(
              onRefresh: () => refresh(context, totalLinks),
              color: primary600,
              child: ListView.separated(
                itemCount: totalLinks.length,
                physics: const AlwaysScrollableScrollPhysics(),
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
                                'user': link.user,
                                'folders': await context
                                    .read<GetUserFoldersCubit>()
                                    .getFolders(link.user!.id!)
                              },
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  makeImagePath(link.user?.profileImg ?? '01'),
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
                                          link.user?.nickname ?? '',
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
                                                link.user?.jobGroup?.name ?? '',
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
                                    onTap: () => showLinkOptionsDialog(
                                      link,
                                      parentContext,
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

  Widget buildJobListView(
    BuildContext jobContext,
    List<JobGroup> jobs,
    List<Link> totalLinks,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 30 - 7, left: 12, right: 20),
      child: DefaultTabController(
        length: jobs.length,
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
                    for (final job in jobs) {
                      tabs.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
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
                        final selectedJobGroupId = jobs[index].id!;
                        jobContext
                            .read<LinksFromSelectedJobGroupCubit>()
                            .getSelectedJobLinks(selectedJobGroupId, 0);
                        totalLinks.clear();
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
    totalLinks.clear();
    unawaited(context.read<LinksFromSelectedJobGroupCubit>().refresh());
  }
}
