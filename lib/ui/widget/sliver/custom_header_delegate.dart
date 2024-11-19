
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomHeaderDelegate extends SliverPersistentHeaderDelegate {
  CustomHeaderDelegate(this.child, {this.max = 55, this.min = 55});

  final Widget child;
  final double max;
  final double min;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => max.h;

  @override
  double get minExtent => min.h;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
