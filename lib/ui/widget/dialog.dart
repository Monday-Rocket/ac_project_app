import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/resource.dart';
import 'package:flutter/material.dart';

void showPopUp({
  required String title,
  required String content,
  required BuildContext parentContext,
  required void Function()? callback,
  bool icon = false,
}) {
  final width = MediaQuery.of(parentContext).size.width;
  showDialog<dynamic>(
    context: parentContext,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Container(
              width: width - (45 * 2),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: icon ? 14 : 16,
                  ),
                  if (icon)
                    const Icon(
                      Icons.error,
                      color: primary800,
                      size: 27,
                    ),
                  Container(
                    margin: EdgeInsets.only(top: icon ? 7 : 0, bottom: 10),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: R_Font.PRETENDARD,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: grey500,
                      fontSize: 14,
                      letterSpacing: -0.1,
                      fontWeight: FontWeight.w500,
                      height: 16.7 / 14,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                      left: 4,
                      right: 4,
                      bottom: 4,
                      top: 32,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: callback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text(
                          '??????',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 5,
              top: 5,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.close,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showMyPageDialog({
  required String title,
  required String content,
  required BuildContext parentContext,
  required String leftText,
  required String rightText,
  required void Function()? leftCallback,
  required void Function()? rightCallback,
  bool icon = false,
}) {
  final width = MediaQuery.of(parentContext).size.width;
  showDialog<dynamic>(
    context: parentContext,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Container(
              width: width - (45 * 2),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: icon ? 14 : 16,
                  ),
                  if (icon)
                    const Icon(
                      Icons.error,
                      color: grey800,
                      size: 27,
                    ),
                  Container(
                    margin: EdgeInsets.only(top: icon ? 7 : 0, bottom: 10),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: R_Font.PRETENDARD,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: grey500,
                      fontSize: 14,
                      letterSpacing: -0.1,
                      fontWeight: FontWeight.w500,
                      height: 16.7 / 14,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                      left: 4,
                      right: 4,
                      bottom: 4,
                      top: 32,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: leftCallback,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: grey200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                shadowColor: Colors.transparent,
                              ),
                              child: Text(
                                leftText,
                                style: const TextStyle(
                                  color: grey800,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: rightCallback,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: grey800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                shadowColor: Colors.transparent,
                              ),
                              child: Text(
                                rightText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
            Positioned(
              right: 5,
              top: 5,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.close,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showError(BuildContext context) {
  showPopUp(
    title: '?????? ??????',
    content: '?????? ?????? ??????',
    parentContext: context,
    callback: () => Navigator.pop(context),
    icon: true,
  );
}
