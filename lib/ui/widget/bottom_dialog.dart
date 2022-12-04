import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/links/delete_link.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/report/report_type.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future<bool?> showMyLinkOptionsDialog(Link link, BuildContext parentContext) {
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
                decoration: _dialogDecoration(),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 29,
                  ),
                  child: Column(
                    children: [
                      buildTitle(context, '링크 옵션'),
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
                              onTap: () => Share.share(
                                link.url ?? '',
                                subject: link.title,
                              ),
                              highlightColor: grey100,
                              child: buildItem('공유'),
                            ),
                            InkWell(
                              onTap: () {
                                DeleteLink.delete(link).then((result) {
                                  Navigator.pop(context);
                                  Navigator.pop(parentContext, 'deleted');
                                });
                              },
                              child: buildItem('링크 삭제'),
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

Future<bool?> showLinkOptionsDialog(Link link, BuildContext parentContext, {void Function()? callback}) {
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
                decoration: _dialogDecoration(),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 29,
                  ),
                  child: Column(
                    children: [
                      buildTitle(context, '링크 옵션'),
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
                              onTap: () => Share.share(
                                link.url ?? '',
                                subject: link.title,
                              ),
                              highlightColor: grey100,
                              child: buildItem('공유'),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  Routes.report,
                                  arguments: {
                                    'type': ReportType.post,
                                    'id': link.id,
                                    'name': link.title,
                                  },
                                ).then((value) {
                                  Navigator.pop(context);
                                  callback?.call();
                                });
                              },
                              child: buildItem('신고하기'),
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

Future<bool?> showUserOptionDialog(BuildContext parentContext, DetailUser user, {void Function()? callback}) {
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
                decoration: _dialogDecoration(),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 29,
                  ),
                  child: Column(
                    children: [
                      buildTitle(context, '사용자 옵션'),
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
                              onTap: () {
                                Navigator.pushNamed(
                                  parentContext,
                                  Routes.report,
                                  arguments: {
                                    'type': ReportType.user,
                                    'id': user.id,
                                    'name': user.nickname,
                                  },
                                ).then((_) {
                                  Navigator.pop(context);
                                  callback?.call();
                                });
                              },
                              child: buildItem('신고하기'),
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

Container buildTitle(BuildContext context, String title) {
  return Container(
    margin: const EdgeInsets.only(left: 30, right: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
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
  );
}

Container buildItem(String text) {
  return Container(
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
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: blackBold,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    ),
  );
}

BoxDecoration _dialogDecoration() {
  return const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    ),
  );
}
