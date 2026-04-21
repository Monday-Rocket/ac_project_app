// ignore_for_file: avoid_positional_boolean_parameters, non_constant_identifier_names

import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/auth/auth_cubit.dart';
import 'package:ac_project_app/cubits/links/link_check_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/provider/sync/sync_repository.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 심플 헤더
          Padding(
            padding: EdgeInsets.only(
              top: 60.w,
              left: 24.w,
              right: 24.w,
              bottom: 24.w,
            ),
            child: Text(
              '설정',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28.sp,
                color: grey900,
              ),
            ),
          ),
          _AccountSection(),
          _BackupSection(),
          MenuList(context),
        ],
      ),
    );
  }

  Widget _AccountSection() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.w),
          child: state.isLoggedIn
              ? _LoggedInView(context, state)
              : _LoginButtons(context, state),
        );
      },
    );
  }

  Widget _LoggedInView(BuildContext context, AuthState state) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20.w,
          backgroundColor: grey200,
          backgroundImage: state.user?.userMetadata?['avatar_url'] != null
              ? NetworkImage(state.user!.userMetadata!['avatar_url'] as String)
              : null,
          child: state.user?.userMetadata?['avatar_url'] == null
              ? Icon(Icons.person, size: 20.w, color: grey500)
              : null,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.user?.email ?? '',
                style: TextStyle(fontSize: 14.sp, color: grey900, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              if (state.isPro)
                Text('Pro', style: TextStyle(fontSize: 12.sp, color: primary600, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.read<AuthCubit>().signOut(),
          child: Text('로그아웃', style: TextStyle(fontSize: 12.sp, color: grey500)),
        ),
      ],
    );
  }

  Widget _LoginButtons(BuildContext context, AuthState state) {
    final isLoading = state.status == AuthStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '로그인하여 Pro 기능을 사용하세요',
          style: TextStyle(fontSize: 13.sp, color: grey500),
        ),
        SizedBox(height: 12.w),
        SizedBox(
          width: double.infinity,
          height: 44.w,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => context.read<AuthCubit>().signInWithGoogle(),
            icon: Icon(Icons.g_mobiledata, size: 24.w),
            label: Text('Google로 로그인', style: TextStyle(fontSize: 14.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: grey900,
              elevation: 0,
              side: BorderSide(color: grey200, width: 1.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
            ),
          ),
        ),
        if (Platform.isIOS) ...[
          SizedBox(height: 8.w),
          SizedBox(
            width: double.infinity,
            height: 44.w,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : () => context.read<AuthCubit>().signInWithApple(),
              icon: Icon(Icons.apple, size: 20.w),
              label: Text('Apple로 로그인', style: TextStyle(fontSize: 14.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
              ),
            ),
          ),
        ],
        if (state.errorMessage != null) ...[
          SizedBox(height: 8.w),
          Text(
            state.errorMessage!,
            style: TextStyle(fontSize: 11.sp, color: Colors.red),
          ),
        ],
        SizedBox(height: 16.w),
      ],
    );
  }

  Widget _BackupSection() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (!state.isPro) return const SizedBox.shrink();
        return const _BackupCard();
      },
    );
  }

  Widget MenuList(BuildContext context) {
    Widget DivisionLine({double size = 4}) {
      return Container(
        height: size,
        width: MediaQuery.of(context).size.width,
        color: grey200,
      );
    }

    Widget MenuItem(
      String menuName, {
      bool arrow = true,
      Color color = grey900,
      IconData? icon,
    }) {
      return InkWell(
        key: Key('menu:$menuName'),
        onTap: () {
          switch (menuName) {
            case '깨진 링크 체크':
              _showLinkCheckDialog(context);
              break;
            case '이용 약관':
              launchUrl(
                Uri.parse(approveSecondLink),
                mode: LaunchMode.externalApplication,
              );
              break;
            case '개인정보 처리방침':
              launchUrl(
                Uri.parse(personalInfoLink),
                mode: LaunchMode.externalApplication,
              );
              break;
            case '도움말':
              launchUrl(
                Uri.parse(helpLink),
                mode: LaunchMode.externalApplication,
              );
              break;
            case '오픈소스 라이센스':
              Navigator.pushNamed(context, Routes.ossLicenses);
              break;
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 20.w,
            horizontal: 24.w,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18.w, color: primary700),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: Text(
                  menuName,
                  style: TextStyle(
                    color: color,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (arrow) Icon(Icons.arrow_forward_ios_rounded, size: 16.w),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        DivisionLine(),
        MenuItem('깨진 링크 체크', icon: Icons.link_off),
        DivisionLine(size: 1.w),
        MenuItem('이용 약관'),
        DivisionLine(size: 1.w),
        MenuItem('개인정보 처리방침'),
        DivisionLine(size: 1.w),
        MenuItem('도움말'),
        DivisionLine(size: 1.w),
        MenuItem('오픈소스 라이센스'),
        DivisionLine(),
      ],
    );
  }

  void _showLinkCheckDialog(BuildContext context) {
    final cubit = LinkCheckCubit(
      linkRepository: getIt<LocalLinkRepository>(),
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<LinkCheckCubit, LinkCheckState>(
          builder: (context, state) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.w),
              ),
              title: Text(
                '깨진 링크 체크',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: grey900,
                ),
              ),
              content: _linkCheckContent(state),
              actions: _linkCheckActions(context, state, cubit),
            );
          },
        ),
      ),
    ).then((_) => cubit.close());

    cubit.checkAllLinks();
  }

  Widget _linkCheckContent(LinkCheckState state) {
    if (state.status == LinkCheckStatus.checking) {
      final progress = state.total > 0 ? state.checked / state.total : 0.0;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.w),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.w),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.w,
              backgroundColor: grey200,
              valueColor: const AlwaysStoppedAnimation<Color>(primary700),
            ),
          ),
          SizedBox(height: 12.w),
          Text(
            state.progressText,
            style: TextStyle(fontSize: 13.sp, color: grey600),
          ),
        ],
      );
    }

    if (state.status == LinkCheckStatus.error) {
      return Text(
        state.errorMessage ?? '오류가 발생했습니다',
        style: TextStyle(fontSize: 13.sp, color: redError),
      );
    }

    if (state.status == LinkCheckStatus.done) {
      if (state.brokenLinks.isEmpty) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 40.w, color: primary600),
            SizedBox(height: 8.w),
            Text(
              '모든 링크가 정상입니다!',
              style: TextStyle(fontSize: 14.sp, color: grey700),
            ),
          ],
        );
      }

      return SizedBox(
        width: double.maxFinite,
        height: 240.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.doneText,
              style: TextStyle(
                fontSize: 13.sp,
                color: redError,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.w),
            Expanded(
              child: BlocBuilder<LinkCheckCubit, LinkCheckState>(
                builder: (context, currentState) {
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: currentState.brokenLinks.length,
                    separatorBuilder: (_, __) => SizedBox(height: 4.w),
                    itemBuilder: (context, index) {
                      final link = currentState.brokenLinks[index];
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.w,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F1),
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    link.title ?? link.url,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: grey700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    link.status != null
                                        ? 'HTTP ${link.status}'
                                        : '연결 실패',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context
                                  .read<LinkCheckCubit>()
                                  .deleteBrokenLink(link.linkId),
                              child: Padding(
                                padding: EdgeInsets.only(left: 8.w),
                                child: Text(
                                  '삭제',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: redError,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget> _linkCheckActions(
    BuildContext context,
    LinkCheckState state,
    LinkCheckCubit cubit,
  ) {
    if (state.status == LinkCheckStatus.checking) {
      return [];
    }

    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          '닫기',
          style: TextStyle(fontSize: 14.sp, color: grey600),
        ),
      ),
    ];
  }
}

class _BackupCard extends StatefulWidget {
  const _BackupCard();

  @override
  State<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<_BackupCard> {
  late final SyncRepository _sync = getIt<SyncRepository>();
  DateTime? _lastBackupAt;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _refreshLastBackup();
  }

  Future<void> _refreshLastBackup() async {
    final at = await _sync.getLastBackupAt();
    if (mounted) setState(() => _lastBackupAt = at);
  }

  Future<void> _backupNow() async {
    if (_running) return;
    setState(() => _running = true);
    try {
      final ok = await _sync.backupToRemote();
      if (!mounted) return;
      showBottomToast(
        ok ? '백업 완료' : '백업에 실패했어요',
        context: context,
      );
      await _refreshLastBackup();
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _restore() async {
    if (_running) return;
    final hasRemote = await _sync.hasRemoteBackup();
    if (!mounted) return;
    if (!hasRemote) {
      showBottomToast('백업된 데이터가 없습니다', context: context);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('백업에서 복원', style: TextStyle(fontSize: 16.sp)),
        content: Text(
          '현재 기기의 데이터가 삭제되고 백업으로 덮어써집니다. 계속할까요?',
          style: TextStyle(fontSize: 13.sp, color: grey700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('복원', style: TextStyle(color: primary600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _running = true);
    try {
      await _sync.restoreFromRemote();
      if (!mounted) return;
      showBottomToast('복원 완료', context: context);
    } catch (e) {
      if (!mounted) return;
      showBottomToast('복원에 실패했어요', context: context);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: primary100,
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined, size: 18.sp, color: primary700),
              SizedBox(width: 8.w),
              Text(
                '백업 & 복원',
                style: TextStyle(
                  color: grey900,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.w),
          Text(
            _lastBackupAt == null
                ? '아직 백업된 적이 없습니다'
                : '마지막 백업: ${_formatDate(_lastBackupAt!)}',
            style: TextStyle(color: grey700, fontSize: 12.sp),
          ),
          SizedBox(height: 12.w),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? null : _backupNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                  ),
                  child: Text(
                    _running ? '진행 중…' : '지금 백업',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: _running ? null : _restore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary700,
                    side: BorderSide(color: primary600, width: 1.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                  ),
                  child: Text(
                    '백업에서 복원',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
