import 'dart:async';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/home_view_cubit.dart';
import 'package:ac_project_app/cubits/linkpool_pick/linkpool_pick_cubit.dart';
import 'package:ac_project_app/cubits/links/get_links_cubit.dart';
import 'package:ac_project_app/cubits/links/upload_link_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/api/folders/share_folder_api.dart';
import 'package:ac_project_app/provider/global_variables.dart';
import 'package:ac_project_app/provider/kakao/kakao.dart';
import 'package:ac_project_app/provider/manager/app_pause_manager.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/home/home_page.dart';
import 'package:ac_project_app/ui/page/my_folder/my_folder_page.dart';
import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:app_links/app_links.dart';
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
    receiveInviteLink();
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
          const MyFolderPage(),
          MultiBlocProvider(
            providers: [
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

  void receiveInviteLink() {
    AppLinks().uriLinkStream.listen((uri) {
      Log.i('Received URI: $uri');
      if (!mounted) return;
      processInviteLink(uri);
    });
    if (appLinkUrl.isNotEmpty) {
      processInviteLink(Uri.parse(appLinkUrl));
      appLinkUrl = '';
    }
  }

  void processInviteLink(Uri uri) {
    if (uri.queryParameters.containsKey('token') && uri.queryParameters.containsKey('id')) {
      final inviteToken = uri.queryParameters['token'] ?? '';
      final folderId = uri.queryParameters['id'] ?? '';
      getIt<ShareFolderApi>().acceptInviteLink(folderId, inviteToken).then((result) {
        result.map(
          success: (_) async {
            (await getIt<FolderApi>().getMyFolders()).map(
              success: (data) {
                for (var i = 0; i < data.data.length; i++) {
                  final folder = data.data[i];
                  if (folder.id == int.parse(folderId)) {
                    ShareDB.insert(folder);
                    Navigator.pushNamed(context, Routes.myLinks, arguments: {
                      'folders': data.data,
                      'selectedFolder': folder,
                      'tabIndex': i,
                    });
                    break;
                  }
                }
              },
              error: (msg) {
                showBottomToast(
                  context: context,
                  '폴더 정보를 불러오지 못했어요. 다시 시도해주세요.',
                );
              },
            );

            showBottomToast(
              context: context,
              '초대 링크를 수락했어요!',
            );
          },
          error: (msg) {},
        );
      });
    }
  }
}
