// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/home/local_search_links_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/cubits/links/local_upload_link_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
import 'package:ac_project_app/ui/widget/link_hero.dart';
import 'package:ac_project_app/ui/widget/user/user_info.dart';
import 'package:ac_project_app/util/get_arguments.dart';
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

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LocalSearchLinksCubit(),
        ),
        BlocProvider(create: (_) => LocalUploadLinkCubit()),
      ],
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
              appBar: _buildAppBar(context, isMine),
              body: buildListBody(context, isMine),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
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
        icon: SvgPicture.asset(Assets.images.icBack,
            width: 24.w, height: 24.w, fit: BoxFit.cover),
        color: grey900,
        padding: EdgeInsets.only(left: 20.w, right: 8.w),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
        ),
      ),
      leadingWidth: 44.w,
      toolbarHeight: 48.w,
      title:
          searchState ? buildSearchBar(isMine, context) : buildEmptySearchBar(),
      titleSpacing: 0,
      actions: [
        Center(
          child: InkWell(
            onTap: () => onTapSearch(isMine, context),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 22.w,
                top: 8.w,
                bottom: 8.w,
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

  void onTapSearch(bool isMine, BuildContext context) {
    if (buttonState) {
      context.read<LocalSearchLinksCubit>().clear();
      final text = textController.text;
      if (isMine) {
        context.read<LocalSearchLinksCubit>().searchMyLinks(text, 0);
      } else {
        context.read<LocalSearchLinksCubit>().searchLinks(text, 0);
      }
    }
  }

  Widget buildListBody(
    BuildContext parentContext,
    bool isMine,
  ) {
    final width = MediaQuery.of(parentContext).size.width;

    return BlocBuilder<LocalSearchLinksCubit, LinkListState>(
      builder: (context, state) {
        final totalLinks = context.read<LocalSearchLinksCubit>().totalLinks;
        if (totalLinks.isEmpty) {
          return Center(
            child: Text(
              '',
              style: TextStyle(
                color: grey300,
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
                height: 19 / 16,
              ),
            ),
          );
        } else {
          return NotificationListener<ScrollStartNotification>(
            onNotification: (scrollStart) {
              FocusManager.instance.primaryFocus?.unfocus();
              return true;
            },
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (scrollEnd) {
                final metrics = scrollEnd.metrics;
                if (metrics.extentAfter <= 800) {
                  context.read<LocalSearchLinksCubit>().loadMore();
                }
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
                          vertical: 20.w,
                          horizontal: 24.w,
                        ),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserInfoWidget(context: context, link: link),
                            if (link.describe != null &&
                                (link.describe?.isNotEmpty ?? false))
                              Column(
                                children: [
                                  SizedBox(
                                    height: 17.w,
                                  ),
                                  Text(
                                    link.describe ?? '',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: grey800,
                                      height: 26 / 16,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const SizedBox.shrink(),
                            Container(
                              margin: EdgeInsets.only(
                                top: 16.w,
                                bottom: 18.w,
                              ),
                              child: LinkHero(
                                tag: 'linkImage${link.id}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(7.w),
                                  ),
                                  child: hasHttpImageUrl(link)
                                      ? Container(
                                          constraints: const BoxConstraints(
                                            minWidth: double.infinity,
                                          ),
                                          color: grey100,
                                          child: CachedNetworkImage(
                                            imageUrl: link.image ?? '',
                                            fadeInDuration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            fadeOutDuration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            imageBuilder:
                                                (context, imageProvider) =>
                                                    Container(
                                              height: 160.w,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      width: width - (24 * 2 + 25).w,
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
                                        width: 25.w,
                                        height: 25.w,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.w),
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
                  },
                  separatorBuilder: (_, __) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child:
                        Divider(height: 1.w, thickness: 1.w, color: ccGrey200),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget buildSearchBar(bool isMine, BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(left: 10.w),
        child: BlocBuilder<LocalSearchLinksCubit, LinkListState>(
          builder: (context, state) {
            return Container(
              decoration: BoxDecoration(
                color: grey100,
                borderRadius: BorderRadius.all(Radius.circular(7.w)),
              ),
              height: 36.w,
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
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    onTapSearch(isMine, context);
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    hintText: '검색어를 입력해주세요',
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      letterSpacing: -0.1.w,
                      height: 18 / 14,
                      color: lightGrey700,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 9.w,
                    ),
                    suffixIcon: InkWell(
                      onTap: () {
                        textController.text = '';
                      },
                      child: Icon(
                        CupertinoIcons.clear_circled_solid,
                        color: grey400,
                        size: 20.w,
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
            );
          },
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
              borderRadius: BorderRadius.all(Radius.circular(7.w)),
            ),
            height: 36.w,
            margin: EdgeInsets.only(right: 6.w),
            child: Center(
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 10.w, right: 10.w),
                    child: Assets.images.folderSearchIcon.image(
                      width: 18.w,
                      height: 18.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Text(
                    '검색어를 입력해주세요',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                      letterSpacing: -0.1.w,
                      height: 18 / 14,
                      color: lightGrey700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> refresh(BuildContext context, List<Link> totalLinks) async {
    context.read<LocalSearchLinksCubit>().refresh();
  }
}
