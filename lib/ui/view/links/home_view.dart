import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/consts.dart';
import 'package:ac_project_app/cubits/folders/folder_view_type_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/home/get_job_list_cubit.dart';
import 'package:ac_project_app/cubits/home_view_cubit.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_job_group_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/home/home_page.dart';
import 'package:ac_project_app/ui/page/my_folder/my_folder_page.dart';
import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/util/get_widget_arguments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      FolderApi().bulkSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = getArguments(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => HomeViewCubit((args['index'] as int?) ?? 0),
        ),
        BlocProvider(
          create: (_) => LinksFromSelectedJobGroupCubit(),
        ),
        BlocProvider<GetFoldersCubit>(
          create: (_) => GetFoldersCubit(),
        ),
        BlocProvider<GetProfileInfoCubit>(
          create: (_) => GetProfileInfoCubit(),
        ),
      ],
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
            backgroundColor: Colors.white,
            body: BlocBuilder<GetProfileInfoCubit, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoadedState) {
                  return IndexedStack(
                    index: index,
                    children: <Widget>[
                      MultiBlocProvider(
                        providers: [
                          BlocProvider(
                            create: (_) => GetJobListCubit(),
                          ),
                          BlocProvider(
                            create: (_) => GetUserFoldersCubit(),
                          ),
                        ],
                        child: HomePage(profile: state.profile),
                      ),
                      const Scaffold(),
                      MultiBlocProvider(
                        providers: [
                          BlocProvider<FolderViewTypeCubit>(
                            create: (_) => FolderViewTypeCubit(),
                          ),
                        ],
                        child: const MyFolderPage(),
                      ),
                      const MyPage(),
                    ],
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primary600,
              selectedFontSize: 10.sp,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w400),
              unselectedItemColor: grey400,
              unselectedFontSize: 10.sp,
              showUnselectedLabels: true,
              items: bottomItems,
              currentIndex: index,
              onTap: (index) {
                if (index == 0) {
                  context.read<LinksFromSelectedJobGroupCubit>().refresh();
                  context.read<HomeViewCubit>().moveTo(index);
                } else if (index == 1) {
                  pushUploadView(context);
                } else if (index == 2) {
                  context.read<GetFoldersCubit>().getFolders();
                  context.read<HomeViewCubit>().moveTo(index);
                } else {
                  context.read<HomeViewCubit>().moveTo(index);
                }
              },
            ),
          );
        },
      ),
    );
  }

  void pushUploadView(BuildContext context) {
    Navigator.pushNamed(context, Routes.upload).then(
      (value) => setState(
        () {
          if (NavigatorPopResult.saveLink == value) {
            showBottomToast(
              context: context,
              '링크가 저장되었어요!',
              callback: () {
                context.read<GetFoldersCubit>().getFolders();
                context.read<HomeViewCubit>().moveTo(2);
              },
            );
          }
        },
      ),
    );
  }

  List<SvgPicture> getBottomIcons(int index) {
    final enabledIcons = [
      SvgPicture.asset(Assets.images.icHome),
      SvgPicture.asset(Assets.images.icUpload),
      SvgPicture.asset(Assets.images.icMyfolder),
      SvgPicture.asset(Assets.images.icMypage),
    ];

    final disabledIcons = [
      SvgPicture.asset(Assets.images.icHomeDisabled),
      SvgPicture.asset(Assets.images.icUploadDisabled),
      SvgPicture.asset(Assets.images.icMyfolderDisabled),
      SvgPicture.asset(Assets.images.icMypageDisabled),
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
