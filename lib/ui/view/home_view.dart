import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/auth/auth_cubit.dart';
import 'package:ac_project_app/cubits/folders/local_folders_cubit.dart';
import 'package:ac_project_app/cubits/home_view_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/auth/auth_repository.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/provider/sync/pro_remote_hooks.dart';
import 'package:ac_project_app/provider/sync/sync_repository.dart';
import 'package:ac_project_app/ui/page/home/local_explore_page.dart';
import 'package:ac_project_app/ui/page/my_folder/my_folder_page.dart';
import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/util/get_arguments.dart';
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
  final uploadToolTipButtonKey = GlobalKey();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    saveLinksFromOutside();
    super.initState();
    // AuthCubit 프로바이더가 빌드된 후 한 프레임 뒤에 dirty 보정 시도
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeRunDirtyCorrectionBackup();
    });
  }

  void saveLinksFromOutside() {
    ShareDataProvider.bulkSaveToLocal().then((value) {
      setState(() {});
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
      ShareDataProvider.bulkSaveToLocal();

      // plan 재조회 + 전환 감지 + dirty 시 보정 백업 (Pro)
      if (mounted) {
        context.read<AuthCubit>().refreshPlan();
        _maybeRunDirtyCorrectionBackup();
      }
    }
  }

  Future<void> _maybeRunDirtyCorrectionBackup() async {
    final authCubit = context.read<AuthCubit>();
    if (!authCubit.state.isPro) return;
    final sync = getIt<SyncRepository>();
    if (await sync.isDirty()) {
      await sync.backupToRemote();
    }
  }

  bool _autoRestorePromptShown = false;

  Future<void> _maybeShowAutoRestorePrompt() async {
    if (_autoRestorePromptShown) return;
    if (!mounted) return;
    final authCubit = context.read<AuthCubit>();
    if (!authCubit.state.isPro) return;

    final sync = getIt<SyncRepository>();
    final linkRepo = getIt<LocalLinkRepository>();
    final localEmpty = (await linkRepo.getTotalLinkCount()) == 0;
    if (!localEmpty) return;
    final hasRemote = await sync.hasRemoteBackup();
    if (!hasRemote) return;
    if (!mounted) return;
    _autoRestorePromptShown = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('백업 발견', style: TextStyle(fontSize: 16.sp)),
        content: Text(
          '계정에 연결된 백업 데이터가 있습니다. 이 기기로 복원할까요?',
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('나중에'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('복원'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await sync.restoreFromRemote();
        if (!mounted) return;
        context.read<LocalFoldersCubit>().getFolders();
      } catch (_) {
        // 실패는 로그만
      }
    }
  }

  void _configureProHooks(AuthCubit authCubit) {
    final sync = getIt<SyncRepository>();
    ProRemoteHooks.configure(
      isPro: () => authCubit.state.isPro,
      upsertFolder: sync.upsertFolderRemote,
      upsertLink: sync.upsertLinkRemote,
      deleteFolder: sync.deleteFolderRemote,
      deleteLink: sync.deleteLinkRemote,
    );
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
        BlocProvider<LocalFoldersCubit>(
          create: (_) => LocalFoldersCubit(rootsOnly: true),
        ),
        BlocProvider<AuthCubit>(
          create: (_) {
            final authCubit = AuthCubit(
              authRepository: getIt<AuthRepository>(),
              syncRepository: getIt<SyncRepository>(),
            );
            _configureProHooks(authCubit);
            return authCubit;
          },
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (prev, curr) => prev.isPro != curr.isPro,
        listener: (context, state) {
          if (state.isPro) _maybeShowAutoRestorePrompt();
        },
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
        children: const <Widget>[
          MyFolderPage(),
          LocalExplorePage(),
          MyPage(),
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
            context.read<LocalFoldersCubit>().getFolders();
          }
          context.read<HomeViewCubit>().moveTo(index);
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

}
