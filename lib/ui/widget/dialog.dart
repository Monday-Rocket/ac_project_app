import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/resource.dart';
import 'package:flutter/material.dart';

void showPopUp({
  required String title,
  required String content,
  required BuildContext parentContext,
  required void Function() callback,
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
                  Text(content, textAlign: TextAlign.center),
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
                        ),
                        child: const Text(
                          '확인',
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

void showError(BuildContext context) {
  showPopUp(
    title: '서버 에러',
    content: '서버 통신 오류',
    parentContext: context,
    callback: () => Navigator.pop(context),
    icon: true,
  );
}
