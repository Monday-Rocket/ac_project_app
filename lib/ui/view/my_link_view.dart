import 'package:ac_project_app/util/get_json_argument.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyLinkView extends StatelessWidget {
  const MyLinkView({super.key});

  @override
  Widget build(BuildContext context) {

    final arg = getJsonArgument(context);
    final folder = arg['folder'];
    Log.i(folder);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 24, right: 20, top: 47),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '디자인',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: SvgPicture.asset('assets/images/ic_lock.svg'),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {},
                    child: SvgPicture.asset('assets/images/more.svg'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
