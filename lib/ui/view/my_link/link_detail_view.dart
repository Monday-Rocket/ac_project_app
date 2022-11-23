// ignore_for_file: avoid_positional_boolean_parameters

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/links/delete_link.dart';
import 'package:ac_project_app/cubits/links/detail_edit_cubit.dart';
import 'package:ac_project_app/cubits/links/edit_state.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/util/date_utils.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkDetailView extends StatelessWidget {
  const LinkDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = getArguments(context);
    final link = args['link'] as Link;
    final scrollController = ScrollController();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DetailEditCubit(link),
        ),
      ],
      child: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: KeyboardVisibilityBuilder(
          builder: (context, visible) {
            return BlocBuilder<DetailEditCubit, EditState>(
              builder: (cubitContext, state) {
                return Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: grey900,
                      ),
                    ),
                    actions: [
                      InkWell(
                        onTap: () => showLinkOptionsDialog(link, context),
                        child: Container(
                          margin: const EdgeInsets.only(right: 24),
                          child: SvgPicture.asset(
                            'assets/images/more.svg',
                            width: 25,
                            height: 25,
                          ),
                        ),
                      ),
                    ],
                    systemOverlayStyle: SystemUiOverlayStyle.dark,
                  ),
                  body: Builder(
                    builder: (_) {
                      if (state == EditState.view) {
                        return buildBody(link, cubitContext, state);
                      } else {
                        return SingleChildScrollView(
                          reverse: true,
                          controller: scrollController,
                          child: buildBody(link, cubitContext, state),
                        );
                      }
                    },
                  ),
                  bottomSheet: Builder(
                    builder: (_) {
                      if (state == EditState.edit) {
                        return Container(
                          margin: EdgeInsets.only(
                            top: 16,
                            bottom: visible ? 16 : 37,
                            left: 24,
                            right: 24,
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(55),
                              backgroundColor: primary700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              cubitContext
                                  .read<DetailEditCubit>()
                                  .saveComment(link)
                                  .then(
                                    (value) =>
                                        value ? Navigator.pop(context) : null,
                                  );
                            },
                            child: const Text(
                              '확인',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              textWidthBasis: TextWidthBasis.parent,
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildBody(Link link, BuildContext context, EditState state) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                await launchUrl(
                  Uri.parse(link.url ?? ''),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F444C94),
                      spreadRadius: 10,
                      blurRadius: 10,
                      offset: Offset(12, 15),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      child: Image.network(
                        link.image ?? '',
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width - 48,
                        height: 193,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width - 48,
                            height: 10,
                          );
                        },
                      ),
                    ),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(19, 23, 19, 33),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getSafeTitleText(link.title),
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: blackBold,
                                  letterSpacing: -0.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 7),
                                child: Text(
                                  link.url ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFC0C2C4),
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 44,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getMonthDayYear(link.time ?? ''),
                  style: const TextStyle(
                    fontSize: 12,
                    color: grey400,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                InkWell(
                  onTap: () => context.read<DetailEditCubit>().toggle(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/images/ic_write_comment.svg',
                    ),
                  ),
                ),
              ],
            ),
            Container(
              color: const Color(0xffecedee),
              height: 1,
              width: double.infinity,
            ),
            Builder(
              builder: (_) {
                if (state == EditState.view) {
                  return Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: Text(
                          link.describe ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: grey700,
                            letterSpacing: -0.1,
                            height: 26 / 16,
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 13, bottom: 50),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          color: grey100,
                        ),
                        child: Scrollbar(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.zero,
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: 120,
                              ),
                              child: TextField(
                                controller: context
                                    .read<DetailEditCubit>()
                                    .textController,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: grey700,
                                ),
                                cursorColor: primary600,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(17),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            Visibility(
              visible: state == EditState.view,
              child: Container(
                margin: const EdgeInsets.only(top: 22, bottom: 40),
                color: const Color(0xffecedee),
                height: 1,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> showLinkOptionsDialog(Link link, BuildContext parentContext) {
    return showModalBottomSheet<bool?>(
      backgroundColor: Colors.transparent,
      context: parentContext,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            StatefulBuilder(
              builder: (context, setState) {
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 29,
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 30, right: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '링크 옵션',
                                style: TextStyle(
                                  color: blackBold,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                            top: 17,
                            left: 6,
                            right: 6,
                            bottom: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => Share.share(link.url ?? ''),
                                highlightColor: grey100,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  padding: const EdgeInsets.only(
                                    top: 14,
                                    bottom: 14,
                                    left: 24,
                                  ),
                                  child: const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '공유',
                                      style: TextStyle(
                                        color: blackBold,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  DeleteLink.delete(link).then((result) {
                                    Navigator.pop(context);
                                    Navigator.pop(parentContext, 'deleted');
                                  });
                                  // deleteLink(context, link);
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    color: Colors.transparent,
                                  ),
                                  padding: const EdgeInsets.only(
                                    top: 14,
                                    bottom: 14,
                                    left: 24,
                                  ),
                                  child: const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '링크 삭제',
                                      style: TextStyle(
                                        color: blackBold,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
