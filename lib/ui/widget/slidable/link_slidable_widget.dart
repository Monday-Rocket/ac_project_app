import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class LinkSlidAbleWidget extends StatelessWidget {
  const LinkSlidAbleWidget({
    super.key,
    required this.index,
    required this.link,
    required this.child,
    required this.callback,
  });

  final int index;
  final Link link;
  final Widget child;
  final void Function()? callback;

  @override
  Widget build(BuildContext context) {
    return buildSlidAble();
  }

  Slidable buildSlidAble() {
    return Slidable(
      key: ValueKey(index),
      endActionPane: ActionPane(
        extentRatio: 0.22,
        motion: const ScrollMotion(),
        children: [
          InkWell(
            onTap: callback,
            child: Container(
              width: 80.w,
              color: redError,
              child: Center(
                child: Text(
                  '삭제',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}
