// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/home/search_links_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final textController = TextEditingController();
  bool buttonState = false;
  bool searchState = false;

  @override
  Widget build(BuildContext context) {
    final args = getArguments(context);
    final isMine = args['isMine'] as bool;
    final totalLinks = <Link>[];
    final width = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (_) => SearchLinksCubit(),
      child: GestureDetector(
        onTap: () {
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() {
              searchState = false;
            });
          }
        },
        child: KeyboardVisibilityBuilder(
          builder: (context, visible) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: _buildAppBar(context, totalLinks, isMine),
              body: _buildBody(totalLinks, isMine, width),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    List<Link> totalLinks,
    bool isMine,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: grey100,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: SvgPicture.asset(Assets.images.icBack),
        color: grey900,
        padding: EdgeInsets.only(left: 20.w, right: 8.w),
      ),
      title: searchState ? buildSearchBar() : buildEmptySearchBar(),
      titleSpacing: 0,
      actions: [
        Center(
          child: InkWell(
            onTap: buttonState
                ? () {
                    totalLinks.clear();
                    final text = textController.text;
                    if (isMine) {
                      context.read<SearchLinksCubit>().searchMyLinks(text, 0);
                    } else {
                      context.read<SearchLinksCubit>().searchLinks(text, 0);
                    }
                  }
                : null,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 22.w,
                top: 8.h,
                bottom: 8.h,
              ),
              child: Text(
                '검색',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                  color: buttonState ? grey800 : grey300,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  BlocBuilder<SearchLinksCubit, LinkListState> _buildBody(
    List<Link> totalLinks,
    bool isMine,
    double width,
  ) {
    return BlocBuilder<SearchLinksCubit, LinkListState>(
      builder: (context, state) {
        if (state is LinkListLoadedState) {
          final links = state.links;
          totalLinks.addAll(links);
        }
        return NotificationListener<ScrollEndNotification>(
          onNotification: (scrollEnd) {
            final metrics = scrollEnd.metrics;
            if (metrics.atEdge && metrics.pixels != 0) {
              context.read<SearchLinksCubit>().loadMore();
            }
            return true;
          },
          child: RefreshIndicator(
            onRefresh: () => refresh(context, totalLinks),
            color: primary600,
            child: ListView.separated(
              itemCount: totalLinks.length,
              itemBuilder: (_, index) {
                final link = totalLinks[index];
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.linkDetail,
                      arguments: {
                        'link': link,
                        'isMine': isMine,
                      },
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      vertical: 18.h,
                      horizontal: 24.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 115.h,
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              vertical: 5.h,
                            ),
                            width: width * (130 / 375),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        link.title ?? '',
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                          color: blackBold,
                                          overflow: TextOverflow.ellipsis,
                                          height: (19 / 16).h,
                                        ),
                                      ),
                                      SizedBox(height: 7.h),
                                      Text(
                                        link.describe ?? '\n\n',
                                        maxLines: 2,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: greyText,
                                          overflow: TextOverflow.ellipsis,
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(
                              Radius.circular(7.r),
                            ),
                            child: ColoredBox(
                              color: grey100,
                              child: link.image != null &&
                                      link.image!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: link.image ?? '',
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                        width: 159.w,
                                        height: 116.h,
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
                                    )
                                  : SizedBox(
                                      width: 159.w,
                                      height: 116.h,
                                    ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Divider(height: 1.h, thickness: 1.h, color: greyTab),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildSearchBar() {
    return Center(
      child: Container(
        margin: EdgeInsets.only(left: 10.w),
        child: Container(
          decoration: BoxDecoration(
            color: grey100,
            borderRadius: BorderRadius.all(Radius.circular(7.r)),
          ),
          height: 36.h,
          child: Center(
            child: TextField(
              textAlignVertical: TextAlignVertical.center,
              controller: textController,
              cursorColor: grey800,
              autofocus: true,
              style: TextStyle(
                color: grey800,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                hintText: '검색어를 입력해주세요',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  letterSpacing: -0.1.w,
                  height: (18 / 14).h,
                  color: lightGrey700,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 9.h,
                ),
                suffixIcon: InkWell(
                  onTap: () {
                    textController.text = '';
                  },
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: grey400,
                    size: 20.r,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  buttonState = value.isNotEmpty;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEmptySearchBar() {
    return GestureDetector(
      onTap: () {
        setState(() {
          searchState = true;
        });
      },
      child: Center(
        child: Container(
          margin: EdgeInsets.only(left: 10.w),
          child: Container(
            decoration: BoxDecoration(
              color: grey100,
              borderRadius: BorderRadius.all(Radius.circular(7.r)),
            ),
            height: 36.h,
            margin: EdgeInsets.only(right: 6.w),
            child: Center(
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 10.w, right: 10.w),
                    child: Assets.images.folderSearchIcon.image(),
                  ),
                  Text(
                    '검색어를 입력해주세요',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                      letterSpacing: -0.1.w,
                      height: (18 / 14).h,
                      color: lightGrey700,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> refresh(BuildContext context, List<Link> totalLinks) async {
    if (totalLinks.isNotEmpty) {
      totalLinks.clear();
      unawaited(context.read<SearchLinksCubit>().refresh());
    }
  }
}
