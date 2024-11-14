import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folder_view_type_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/home/get_job_list_cubit.dart';
import 'package:ac_project_app/cubits/home_view_cubit.dart';
import 'package:ac_project_app/cubits/linkpool_pick/linkpool_pick_cubit.dart';
import 'package:ac_project_app/cubits/links/get_links_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_link_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/check_clipboard_link.dart';
import 'package:ac_project_app/provider/kakao/kakao.dart';
import 'package:ac_project_app/provider/manager/app_pause_manager.dart';
import 'package:ac_project_app/provider/upload_state_variable.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/home/home_page.dart';
import 'package:ac_project_app/ui/page/my_folder/my_folder_page.dart';
import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:ac_project_app/util/url_valid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final uploadToolTipButtonKey = GlobalKey();
  final appPauseManager = getIt<AppPauseManager>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    saveLinksFromOutside();
    processAfterGetContext();
    super.initState();
  }

  void saveLinksFromOutside() {
    getIt<FolderApi>().bulkSave().then((value) {
      setState(() {});
    });
  }

  void processAfterGetContext() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final url = await receiveKakaoScheme();
      if (!mounted) return;
      Kakao.receiveLink(context, url: url);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final resumeState = ValueNotifier(true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!resumeState.value) return;
      resetResumeState();
      appPauseManager.showPopupIfPaused(context);
      getIt<FolderApi>().bulkSave();
      Kakao.receiveLink(context);
      navigateToUploadViewIfClipboardIsValid();
    }
  }

  void navigateToUploadViewIfClipboardIsValid() {
    if (isNotUploadState) {
      Clipboard.getData(Clipboard.kTextPlain).then((value) {
        isValidUrl(value?.text ?? '').then((isValid) {
          if (isValid) {
            final url = value!.text;
            if (isClipboardLink(url)) return;
            Clipboard.setData(const ClipboardData(text: ''));
            Navigator.pushNamed(
              context,
              Routes.upload,
              arguments: {
                'url': url,
              },
            );
          }
        });
      });
    }
  }

  void resetResumeState() {
    resumeState.value = false;
    Future.delayed(const Duration(seconds: 3), () {
      resumeState.value = true;
    });
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
          create: (_) => GetLinksCubit(),
        ),
        BlocProvider<GetFoldersCubit>(
          create: (_) => GetFoldersCubit(),
        ),
      ],
      child: BlocBuilder<HomeViewCubit, int>(
        builder: (context, index) {
          final icons = getBottomIcons(index);

          final bottomItems = [
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 24.w,
                height: 24.w,
                child: icons[0],
              ),
              label: '마이폴더',
            ),
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 24.w,
                height: 24.w,
                child: icons[1],
              ),
              label: '탐색',
            ),
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 24.w,
                height: 24.w,
                child: icons[2],
              ),
              label: '마이페이지',
            ),
          ];
          return buildBody(index, bottomItems, context);
        },
      ),
    );
  }

  Widget buildBody(
    int index,
    List<BottomNavigationBarItem> bottomItems,
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: index,
        children: <Widget>[
          MultiBlocProvider(
            providers: [
              BlocProvider<FolderViewTypeCubit>(
                create: (_) => FolderViewTypeCubit(),
              ),
            ],
            child: const MyFolderPage(),
          ),
          MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => GetJobListCubit()),
              BlocProvider(create: (_) => GetUserFoldersCubit()),
              BlocProvider(create: (_) => UploadLinkCubit()),
              BlocProvider(create: (_) => LinkpoolPickCubit()),
            ],
            child: const HomePage(),
          ),
          const MyPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        key: const Key('MainBottomNavigationBar'),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary600,
        selectedFontSize: 10.sp,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        unselectedItemColor: grey400,
        unselectedFontSize: 10.sp,
        showUnselectedLabels: true,
        items: bottomItems,
        currentIndex: index,
        backgroundColor: Colors.white,
        onTap: (index) {
          if (index == 0) {
            context.read<GetFoldersCubit>().getFolders();
            context.read<HomeViewCubit>().moveTo(index);
          } else if (index == 1) {
            context.read<GetLinksCubit>().refresh();
            context.read<HomeViewCubit>().moveTo(index);
          } else {
            context.read<HomeViewCubit>().moveTo(index);
          }
        },
      ),
    );
  }

  List<SvgPicture> getBottomIcons(int index) {
    final enabledIcons = [
      SvgPicture.asset(Assets.images.icMyfolder),
      SvgPicture.asset(Assets.images.icSearch),
      SvgPicture.asset(Assets.images.icMypage),
    ];

    final disabledIcons = [
      SvgPicture.asset(Assets.images.icMyfolderDisabled),
      SvgPicture.asset(Assets.images.icSearchDisabled),
      SvgPicture.asset(Assets.images.icMypageDisabled),
    ];

    final icons = <SvgPicture>[];

    for (var i = 0; i < enabledIcons.length; i++) {
      if (i == index) {
        icons.add(enabledIcons[i]);
      } else {
        icons.add(disabledIcons[i]);
      }
    }
    return icons;
  }

  void checkAppPause(BuildContext context) {
    appPauseManager.showPopupIfPaused(context);
  }
}
