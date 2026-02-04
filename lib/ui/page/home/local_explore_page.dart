import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/links/local_links_cubit.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/link_hero.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 오프라인 모드용 탐색 페이지
/// 로컬에 저장된 모든 링크를 보여줍니다.
class LocalExplorePage extends StatelessWidget {
  const LocalExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LocalLinksCubit(),
      child: SafeArea(
        child: BlocBuilder<LocalLinksCubit, List<Link>>(
          builder: (context, links) {
            final cubit = context.read<LocalLinksCubit>();
            final totalLinks = cubit.totalLinks;

            if (cubit.hasRefresh) {
              totalLinks.clear();
              cubit.hasRefresh = false;
            }

            return NotificationListener<ScrollEndNotification>(
              onNotification: (scrollEnd) {
                final metrics = scrollEnd.metrics;
                if (metrics.axisDirection != AxisDirection.down) {
                  return false;
                }
                if (metrics.extentAfter <= 800) {
                  cubit.loadMore();
                }
                return true;
              },
              child: RefreshIndicator(
                onRefresh: () async => cubit.refresh(),
                color: primary600,
                child: CustomScrollView(
                  controller: cubit.scrollController,
                  slivers: <Widget>[
                    _buildHeader(),
                    _buildSearchBar(context),
                    _buildLinkList(context, totalLinks),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(left: 24.w, top: 20.w, bottom: 8.w),
        child: Text(
          '내 링크 전체보기',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: grey900,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.w),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            Routes.search,
            arguments: {'isMine': true},
          ),
          child: Container(
            decoration: BoxDecoration(
              color: ccGrey100,
              borderRadius: BorderRadius.all(Radius.circular(7.w)),
            ),
            width: double.infinity,
            height: 36.w,
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
    );
  }

  Widget _buildLinkList(BuildContext context, List<Link> links) {
    final height = MediaQuery.of(context).size.height;

    if (links.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: height * 0.6,
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final link = links[index];
          return Column(
            children: [
              _buildLinkItem(context, link),
              if (index != links.length - 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Divider(height: 1.w, thickness: 1.w, color: ccGrey200),
                ),
            ],
          );
        },
        childCount: links.length,
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, Link link) {
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.linkDetail,
        arguments: {
          'link': link,
          'isMine': true,
          'visible': true,
        },
      ),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 20.w, horizontal: 24.w),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (link.describe != null && (link.describe?.isNotEmpty ?? false))
              Padding(
                padding: EdgeInsets.only(bottom: 16.w),
                child: Text(
                  link.describe ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: grey800,
                    height: 26 / 16,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            if (hasHttpImageUrl(link))
              Container(
                margin: EdgeInsets.only(bottom: 16.w),
                child: LinkHero(
                  tag: 'linkImage${link.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(7.w)),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: double.infinity),
                      color: grey100,
                      child: CachedNetworkImage(
                        imageUrl: link.image ?? '',
                        fadeInDuration: const Duration(milliseconds: 300),
                        fadeOutDuration: const Duration(milliseconds: 300),
                        imageBuilder: (context, imageProvider) => Container(
                          height: 160.w,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: width - (24 * 2 + 30).w,
                  child: LinkHero(
                    tag: 'linkTitle${link.id}',
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
              ],
            ),
            SizedBox(height: 6.w),
            LinkHero(
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
          ],
        ),
      ),
    );
  }
}
