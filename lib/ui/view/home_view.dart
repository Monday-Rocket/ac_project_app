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

  /// AuthCubit이 붙어있는 provider 하위 context에서 호출된다는 전제.
  AuthCubit? _authCubitRef;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!resumeState.value) return;
      resetResumeState();
      ShareDataProvider.bulkSaveToLocal();

      // plan 재조회 + 전환 감지 + dirty 시 보정 백업 (Pro)
      final authCubit = _authCubitRef;
      if (authCubit != null) {
        authCubit.refreshPlan();
        _maybeRunDirtyCorrectionBackup(authCubit);
      }
    }
  }

  Future<void> _maybeRunDirtyCorrectionBackup(AuthCubit authCubit) async {
    if (!authCubit.state.isPro) return;
    final sync = getIt<SyncRepository>();
    if (await sync.isDirty()) {
      await sync.backupToRemote();
    }
  }

  bool _autoRestorePromptShown = false;

  Future<void> _maybeShowAutoRestorePrompt(BuildContext ctx) async {
    if (_autoRestorePromptShown) return;

    final authCubit = ctx.read<AuthCubit>();
    if (!authCubit.state.isPro) return;

    final sync = getIt<SyncRepository>();
    final linkRepo = getIt<LocalLinkRepository>();
    final localEmpty = (await linkRepo.getTotalLinkCount()) == 0;
    if (!localEmpty) return;
    final hasRemote = await sync.hasRemoteBackup();
    if (!hasRemote) return;
    if (!ctx.mounted) return;
    _autoRestorePromptShown = true;

    final ok = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => const _AutoRestoreDialog(),
    );
    if (ok == true) {
      try {
        await sync.restoreFromRemote();
        if (!ctx.mounted) return;
        ctx.read<LocalFoldersCubit>().getFolders();
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
      child: Builder(
        builder: (innerCtx) {
          // provider 하위 context에서 AuthCubit 레퍼런스 캡처 (lifecycle 훅용)
          _authCubitRef ??= innerCtx.read<AuthCubit>();
          // 첫 프레임에 dirty 보정 1회
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final cubit = _authCubitRef;
            if (cubit != null) _maybeRunDirtyCorrectionBackup(cubit);
          });
          return BlocListener<AuthCubit, AuthState>(
            listenWhen: (prev, curr) => prev.isPro != curr.isPro,
            listener: (ctx, state) {
              if (state.isPro) _maybeShowAutoRestorePrompt(ctx);
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
      );
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

/// 신규 기기에서 Pro 로그인 직후 노출되는 자동 복구 팝업.
/// 앱 공용 Dialog 스타일(흰 배경, 16.w 라운드, primary CTA)로 맞춤.
class _AutoRestoreDialog extends StatelessWidget {
  const _AutoRestoreDialog();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.w),
      ),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: SizedBox(
        width: width - (24.w * 2),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 28.w, 20.w, 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: const BoxDecoration(
                  color: primary100,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.cloud_download_outlined,
                  size: 28.w,
                  color: primary700,
                ),
              ),
              SizedBox(height: 16.w),
              Text(
                '백업 데이터가 있어요',
                style: TextStyle(
                  color: grey900,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 10.w),
              Text(
                '계정에 저장된 폴더와 링크를\n이 기기로 가져올까요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: grey500,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 24.w),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.w,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: grey600,
                          side: BorderSide(color: grey200, width: 1.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.w),
                          ),
                        ),
                        child: Text(
                          '나중에',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: SizedBox(
                      height: 48.w,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.w),
                          ),
                        ),
                        child: Text(
                          '복원하기',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
