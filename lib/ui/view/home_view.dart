import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/home_second_view_cubit.dart';
import 'package:ac_project_app/cubits/home_view_cubit.dart';
import 'package:ac_project_app/ui/page/home/home_page.dart';
import 'package:ac_project_app/ui/page/my_folder/my_folder_page.dart';
import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/ui/page/upload/view/upload_page.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final args = getArguments(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => HomeViewCubit((args['index'] as int?) ?? 0),
        ),
        BlocProvider(
          create: (_) => HomeSecondViewCubit(),
        ),
      ],
      child: BlocBuilder<HomeSecondViewCubit, int>(
        builder: (context, second) {
          return BlocBuilder<HomeViewCubit, int>(
            builder: (context, index) {
              final icons = getBottomIcons(index);

              final bottomItems = [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.all(2),
                    child: icons[0],
                  ),
                  label: '홈',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.all(2),
                    child: icons[1],
                  ),
                  label: '업로드',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.all(2),
                    child: icons[2],
                  ),
                  label: '마이폴더',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.all(2),
                    child: icons[3],
                  ),
                  label: '마이페이지',
                ),
              ];

              return Scaffold(
                backgroundColor: Colors.white,
                body: IndexedStack(
                  index: index,
                  children: [
                    HomePage(),
                    UploadPage(),
                    MyFolderPage(),
                    MyPage(),
                  ],
                ),
                bottomNavigationBar: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: primary600,
                  selectedFontSize: 10,
                  selectedLabelStyle:
                      const TextStyle(fontWeight: FontWeight.w500),
                  unselectedLabelStyle:
                      const TextStyle(fontWeight: FontWeight.w400),
                  unselectedItemColor: grey400,
                  unselectedFontSize: 10,
                  showUnselectedLabels: true,
                  items: bottomItems,
                  currentIndex: index,
                  onTap: context.read<HomeViewCubit>().moveTo,
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<SvgPicture> getBottomIcons(int index) {
    final enabledIcons = [
      SvgPicture.asset('assets/images/ic_home.svg'),
      SvgPicture.asset('assets/images/ic_upload.svg'),
      SvgPicture.asset('assets/images/ic_myfolder.svg'),
      SvgPicture.asset('assets/images/ic_mypage.svg'),
    ];

    final disabledIcons = [
      SvgPicture.asset('assets/images/ic_home_disabled.svg'),
      SvgPicture.asset('assets/images/ic_upload_disabled.svg'),
      SvgPicture.asset('assets/images/ic_myfolder_disabled.svg'),
      SvgPicture.asset('assets/images/ic_mypage_disabled.svg'),
    ];

    final icons = <SvgPicture>[];

    for (var i = 0; i < 4; i++) {
      if (i == index) {
        icons.add(enabledIcons[i]);
      } else {
        icons.add(disabledIcons[i]);
      }
    }
    return icons;
  }
}

class UnknownPage extends StatefulWidget {
  const UnknownPage({super.key});

  @override
  State<UnknownPage> createState() => _UnknownPageState();
}

class _UnknownPageState extends State<UnknownPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
