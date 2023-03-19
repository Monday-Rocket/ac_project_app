// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/home/search_links_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_dialog.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:ac_project_app/util/string_utils.dart';
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
              body: buildListBody(context, totalLinks, isMine),
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

  Widget buildListBody(
    BuildContext parentContext,
    List<Link> totalLinks,
    bool isMine,
  ) {
    final width = MediaQuery.of(parentContext).size.width;

    return BlocBuilder<SearchLinksCubit, LinkListState>(
      builder: (context, state) {
        if (state is LinkListLoadedState) {
          final links = state.links;
          totalLinks.addAll(links);
        }

        if (totalLinks.isEmpty) {
          return Center(
            child: Text(
              '',
              style: TextStyle(
                color: grey300,
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
                height: (19 / 16).h,
              ),
            ),
          );
        } else {
          return NotificationListener<ScrollEndNotification>(
            onNotification: (scrollNotification) {
              final metrics = scrollNotification.metrics;
              if (metrics.axisDirection != AxisDirection.down) return false;

              return true;
            },
            child: RefreshIndicator(
              onRefresh: () => refresh(context, totalLinks),
              color: primary600,
              child: ListView.separated(
                itemCount: totalLinks.length,
                physics: const ClampingScrollPhysics(),
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
                                  'isMine': profileState.profile.id ==
                                      link.user!.id,
                                },
                              );
                            },
                            child: Row(
                              children: [
                                Image.asset(
                                  makeImagePath(
                                      link.user?.profileImg ?? '01'),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                                link.user?.jobGroup?.name ??
                                                    '',
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
                  child:
                      Divider(height: 1.h, thickness: 1.w, color: ccGrey200),
                ),
              ),
            ),
          );
        }
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
