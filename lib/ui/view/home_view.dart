import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folder_view_type_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/home/get_job_list_cubit.dart';
import 'package:ac_project_app/cubits/home_second_view_cubit.dart';
import 'package:ac_project_app/cubits/home_view_cubit.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_job_group_cubit.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/home/home_page.dart';
import 'package:ac_project_app/ui/page/my_folder/my_folder_page.dart';
import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    FolderApi().bulkSave().then((value) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FolderApi().bulkSave().then((value) {
        setState(() {});
      });
    }
  }

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
                  children: <Widget>[
                    MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (_) => GetJobListCubit(),
                        ),
                        BlocProvider(
                          create: (_) => LinksFromSelectedJobGroupCubit(),
                        ),
                        BlocProvider(
                          create: (_) => GetUserFoldersCubit(),
                        ),
                      ],
                      child: const HomePage(),
                    ),
                    const Scaffold(),
                    MultiBlocProvider(
                      providers: [
                        BlocProvider<FolderViewTypeCubit>(
                          create: (_) => FolderViewTypeCubit(),
                        ),
                        BlocProvider<GetFoldersCubit>(
                          create: (_) => GetFoldersCubit(),
                        ),
                      ],
                      child: const MyFolderPage(),
                    ),
                    const MyPage(),
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
                  onTap: (index) {
                    if (index == 1) {
                      Navigator.pushNamed(context, Routes.upload);
                    } else {
                      context.read<HomeViewCubit>().moveTo(index);
                    }
                  },
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
