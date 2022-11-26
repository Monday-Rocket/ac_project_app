import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/home/get_job_list_cubit.dart';
import 'package:ac_project_app/cubits/home/topic_list_state.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_job_group_cubit.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final totalLinks = <Link>[];
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetJobListCubit(),
        ),
        BlocProvider(
          create: (_) => LinksFromSelectedJobGroupCubit(),
        ),
      ],
      child: BlocBuilder<GetJobListCubit, JobListState>(
        builder: (context, state) {
          if (state is LoadedState) {
            return Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    Container(
                      margin:
                          const EdgeInsets.only(left: 24, right: 24, top: 20),
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
                    buildJobListView(state.jobs),
                    buildListBody(totalLinks),
                  ],
                ),
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Widget buildListBody(List<Link> totalLinks) {
    return BlocBuilder<LinksFromSelectedJobGroupCubit, List<Link>>(
      builder: (context, links) {
        totalLinks.addAll(links);
        return Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: totalLinks.length,
            itemBuilder: (_, i) {
              final link = totalLinks[i];
              return Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          makeImagePath(link.image ?? '01'),
                          width: 32,
                          height: 32,
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
                                      padding: const EdgeInsets.symmetric(
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
                            Text(
                              link.time ?? '',
                              style: const TextStyle(
                                color: grey400,
                                fontSize: 12,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
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
                    Container(
                      margin: const EdgeInsets.only(
                        top: 16,
                        bottom: 18,
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(7),
                        ),
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: double.infinity,
                          ),
                          color: grey100,
                          child: Image.asset(
                            'assets/images/profile/img_01_on.png',
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              link.title ?? '',
                              style: const TextStyle(
                                color: blackBold,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            InkWell(
                              onTap: () {},
                              child: SvgPicture.asset(
                                'assets/images/more_vert.svg',
                              ),
                            ),
                          ],
                        ),
                        Text(
                          link.url ?? '',
                          style: const TextStyle(
                            color: grey500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(
              height: 1,
              color: grey200,
            ),
          ),
        );
      },
    );
  }

  Widget buildJobListView(List<JobGroup> jobs) {
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
                      physics: const ClampingScrollPhysics(),
                      unselectedLabelColor: grey700,
                      labelColor: primaryTab,
                      labelStyle: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        height: 19 / 16,
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: 'Pretendard',
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
                        /* TODO 탭 눌러서 다른 링크 조회 */
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
}
