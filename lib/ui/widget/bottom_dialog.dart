import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/links/delete_link.dart';
import 'package:ac_project_app/models/link/link.dart';
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
                              onTap: () => Share.share(
                                link.url ?? '',
                                subject: link.title,
                              ),
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
                              onTap: () => Share.share(
                                link.url ?? '',
                                subject: link.title,
                              ),
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
                                /* TODO 신고하기 API 연동 */
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
                                    '신고하기',
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

Future<bool?> showUserOptionDialog(BuildContext parentContext) {
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
                              onTap: () {
                                /* TODO 신고하기 API 연동 */
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
                                    '신고하기',
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
