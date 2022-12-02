// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/home/search_links_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

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
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0.5,
                shadowColor: grey100,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_ios_new),
                  color: grey900,
                  padding: const EdgeInsets.only(left: 24, right: 8),
                ),
                title: searchState ? buildSearchBar() : buildEmptySearchBar(),
                titleSpacing: 0,
                actions: [
                  Center(
                    child: GestureDetector(
                      onTap: buttonState
                          ? () {
                              totalLinks.clear();
                              context
                                  .read<SearchLinksCubit>()
                                  .searchLinks(textController.text, 0);
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 22,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Text(
                          '검색',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: buttonState ? grey800 : grey300,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: BlocBuilder<SearchLinksCubit, LinkListState>(
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
                                },
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 24,
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: (width - 24 * 2) - 159 - 20,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                link.title ?? '',
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: blackBold,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 7,
                                              ),
                                              Text(
                                                link.describe ?? '\n\n',
                                                maxLines: 2,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: greyText,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 30),
                                            child: Text(
                                              link.url ?? '',
                                              maxLines: 1,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFC0C2C4),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(7),
                                      ),
                                      child: ColoredBox(
                                        color: grey100,
                                        child: link.image != null &&
                                                link.image!.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: link.image ?? '',
                                                imageBuilder:
                                                    (context, imageProvider) =>
                                                        Container(
                                                  width: 159,
                                                  height: 116,
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
                                            : const SizedBox(
                                                width: 159,
                                                height: 116,
                                              ),
                                      ),
                                    )
                                  ],
                                ),
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
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        child: Container(
          decoration: const BoxDecoration(
            color: grey100,
            borderRadius: BorderRadius.all(Radius.circular(7)),
          ),
          height: 36,
          margin: const EdgeInsets.only(right: 6),
          child: Center(
            child: TextField(
              textAlignVertical: TextAlignVertical.center,
              controller: textController,
              cursorColor: grey800,
              autofocus: true,
              style: const TextStyle(
                color: grey800,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                hintText: '검색어를 입력해주세요',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  letterSpacing: -0.1,
                  height: 18 / 14,
                  color: grey700,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                suffixIcon: InkWell(
                  onTap: () {
                    textController.text = '';
                  },
                  child: const Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: grey400,
                    size: 20,
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
          margin: const EdgeInsets.only(left: 10),
          child: Container(
            decoration: const BoxDecoration(
              color: grey100,
              borderRadius: BorderRadius.all(Radius.circular(7)),
            ),
            height: 36,
            margin: const EdgeInsets.only(right: 6),
            child: Center(
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 10, right: 10),
                    child: Image.asset(
                      'assets/images/folder_search_icon.png',
                    ),
                  ),
                  const Text(
                    '검색어를 입력해주세요',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      letterSpacing: -0.1,
                      height: 18 / 14,
                      color: grey700,
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
    totalLinks.clear();
    unawaited(context.read<SearchLinksCubit>().refresh());
  }
}
