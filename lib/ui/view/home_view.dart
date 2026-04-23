import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/auth/auth_cubit.dart';
import 'package:ac_project_app/cubits/folders/local_folders_cubit.dart';
import 'package:ac_project_app/cubits/home_view_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/auth/auth_repository.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/provider/share_data_provider.dart';
import 'package:ac_project_app/provider/sync/pro_remote_hooks.dart';
import 'package:ac_project_app/provider/sync/sync_repository.dart';
import 'package:ac_project_app/ui/page/home/local_explore_page.dart';
import 'package:ac_project_app/ui/page/my_folder/my_folder_page.dart';
import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/dialog/pro_backup_dialog.dart';
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

      // plan 재조회 + 전환 감지
      final authCubit = _authCubitRef;
      if (authCubit != null) {
        authCubit.refreshPlan();
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
          return BlocListener<AuthCubit, AuthState>(
            listenWhen: (prev, curr) =>
                prev.backupPhase != curr.backupPhase,
            listener: _onBackupPhaseChanged,
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

  /// Free → Pro 전환 시 백업 진행 다이얼로그 생명주기 관리.
  /// - preparing 에지에서 다이얼로그 노출 (중복 방지 플래그 [_backupDialogOpen]).
  /// - done/failed 결과 토스트.
  /// - idle 로 복귀하면 다이얼로그 닫기.
  bool _backupDialogOpen = false;
  void _onBackupPhaseChanged(BuildContext ctx, AuthState state) {
    final phase = state.backupPhase;
    if (state.isBackupInProgress && !_backupDialogOpen) {
      _backupDialogOpen = true;
      final cubit = ctx.read<AuthCubit>();
      showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const ProBackupDialog(),
        ),
      );
    } else if (phase == ProBackupPhase.done) {
      if (ctx.mounted) {
        showBottomToast(context: ctx, '백업을 마쳤어요!');
      }
    } else if (phase == ProBackupPhase.failed) {
      if (ctx.mounted) {
        showBottomToast(context: ctx, '백업에 실패했어요. 잠시 후 다시 시도해 주세요.');
      }
    } else if (phase == ProBackupPhase.idle && _backupDialogOpen) {
      _backupDialogOpen = false;
      Navigator.of(ctx, rootNavigator: true).maybePop();
    }
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
