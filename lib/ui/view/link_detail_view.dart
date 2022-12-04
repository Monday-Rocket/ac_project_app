// ignore_for_file: avoid_positional_boolean_parameters

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/links/detail_edit_cubit.dart';
import 'package:ac_project_app/cubits/links/edit_state.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/ui/widget/bottom_dialog.dart';
import 'package:ac_project_app/util/date_utils.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkDetailView extends StatelessWidget {
  const LinkDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = getArguments(context);
    final link = args['link'] as Link;
    final isMine = args['isMine'] as bool?;
    final scrollController = ScrollController();

    final profileState = context.watch<GetProfileInfoCubit>().state;
    var isMyLink = false;
    if (profileState is ProfileLoadedState) {
      isMyLink = profileState.profile.id == link.user?.id;
    }
    if (isMine ?? false) {
      isMyLink = true;
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DetailEditCubit(link),
        ),
      ],
      child: KeyboardDismissOnTap(
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
                      icon: SvgPicture.asset('assets/images/ic_back.svg'),
                      padding: const EdgeInsets.only(left: 24, right: 8),
                    ),
                    actions: [
                      InkWell(
                        onTap: () => isMyLink
                            ? showMyLinkOptionsDialog(link, context)
                            : showLinkOptionsDialog(
                                link,
                                context,
                                callback: () => Navigator.pop(context),
                              ),
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
                  body: buildBody(
                    link,
                    cubitContext,
                    state,
                    scrollController,
                    isMyLink,
                  ),
                  bottomSheet: Builder(
                    builder: (_) {
                      if (state == EditState.edit) {
                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: 16,
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

  Widget buildBody(
    Link link,
    BuildContext context,
    EditState state,
    ScrollController scrollController,
    bool isMyLink,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      reverse: state == EditState.edit,
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    getMonthDayYear(link.time ?? ''),
                    style: const TextStyle(
                      fontSize: 12,
                      color: grey400,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Visibility(
                  visible: isMyLink,
                  child: GestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Future.delayed(
                        const Duration(milliseconds: 200),
                        context.read<DetailEditCubit>().toggle,
                      );
                    },
                    onDoubleTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Future.delayed(
                        const Duration(milliseconds: 200),
                        context.read<DetailEditCubit>().toggle,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        'assets/images/ic_write_comment.svg',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 22),
              color: const Color(0xffecedee),
              height: 1,
              width: double.infinity,
            ),
            Builder(
              builder: (_) {
                if (state == EditState.view) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 240,
                        ),
                        child: Text(
                          link.describe ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: lightGrey700,
                            letterSpacing: -0.1,
                            height: 26 / 16,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 22, bottom: 47),
                        color: const Color(0xffecedee),
                        height: 1,
                        width: double.infinity,
                      ),
                    ],
                  );
                } else {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 80),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      color: grey100,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 120,
                        ),
                        child: TextField(
                          controller:
                              context.read<DetailEditCubit>().textController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: grey700,
                            height: 19.6 / 14,
                            letterSpacing: -0.1,
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
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
