import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/home_view_cubit.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/my_folder/my_folder_page.dart';
import 'package:ac_project_app/ui/view/my_link_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final widgetOptions = <Widget>[
      const HomePage(),
      const UploadPage(),
      Navigator(
        onGenerateRoute: (settings) {
          if (settings.name == Routes.myLinks) {
            return MaterialPageRoute(
              builder: (_) => const MyLinkView(),
              settings: settings,
            );
          }
          return MaterialPageRoute(builder: (_) => const MyFolderPage());
        },
      ),
      const MyPage(),
    ];

    return BlocProvider(
      create: (_) => HomeViewCubit(),
      child: BlocBuilder<HomeViewCubit, int>(
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
            body: widgetOptions[index],
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primary600,
              selectedFontSize: 10,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w400),
              unselectedItemColor: grey400,
              unselectedFontSize: 10,
              showUnselectedLabels: true,
              items: bottomItems,
              currentIndex: index,
              onTap: (i) {
                context.read<HomeViewCubit>().moveTo(i);
              },
            ),
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

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
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

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
