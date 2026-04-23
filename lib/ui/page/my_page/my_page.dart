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
              if (state.isPro) const _ProCaption(),
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
        child: const _LinkCheckDialog(),
      ),
    ).then((_) => cubit.close());
  }
}

class _LinkCheckDialog extends StatelessWidget {
  const _LinkCheckDialog();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return BlocBuilder<LinkCheckCubit, LinkCheckState>(
      builder: (context, state) {
        final dismissible = state.status != LinkCheckStatus.checking &&
            state.status != LinkCheckStatus.initial;
        return PopScope(
          canPop: dismissible,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.w),
            ),
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SizedBox(
              width: width - 48.w,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.w, 20.w, 20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context, dismissible),
                    SizedBox(height: 14.w),
                    _LinkCheckBody(state: state),
                    SizedBox(height: 20.w),
                    _LinkCheckCta(state: state),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, bool dismissible) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '깨진 링크 체크',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: grey900,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (dismissible)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.close_rounded, size: 24.w, color: grey700),
          ),
      ],
    );
  }
}

class _LinkCheckBody extends StatelessWidget {
  const _LinkCheckBody({required this.state});

  final LinkCheckState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case LinkCheckStatus.initial:
      case LinkCheckStatus.checking:
        return _checking();
      case LinkCheckStatus.empty:
        return _empty();
      case LinkCheckStatus.error:
        return _error();
      case LinkCheckStatus.cancelled:
        return _cancelled();
      case LinkCheckStatus.done:
        return state.brokenLinks.isEmpty ? _allOk() : _brokenList(context);
    }
  }

  Widget _checking() {
    final progress = state.total > 0 ? state.checked / state.total : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 4.w),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.w),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8.w,
            backgroundColor: grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(primary600),
          ),
        ),
        SizedBox(height: 12.w),
        Text(
          state.total == 0 ? '링크를 불러오는 중...' : state.progressText,
          style: TextStyle(fontSize: 14.sp, color: grey500),
        ),
      ],
    );
  }

  Widget _empty() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: const BoxDecoration(
            color: primary100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.link_off, color: primary600, size: 28.w),
        ),
        SizedBox(height: 14.w),
        Text(
          '검사할 링크가 없어요',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: grey900,
          ),
        ),
        SizedBox(height: 6.w),
        Text(
          '저장된 링크가 없어서 검사를 건너뛰었어요',
          style: TextStyle(fontSize: 14.sp, color: grey500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _error() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: redError, size: 28.w),
        SizedBox(height: 10.w),
        Text(
          state.errorMessage ?? '오류가 발생했습니다',
          style: TextStyle(fontSize: 14.sp, color: grey700),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _cancelled() {
    final partial = state.total > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: const BoxDecoration(
            color: grey200,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.stop_rounded, color: grey600, size: 28.w),
        ),
        SizedBox(height: 14.w),
        Text(
          '검사를 중지했어요',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: grey900,
          ),
        ),
        SizedBox(height: 6.w),
        Text(
          partial
              ? '${state.checked}/${state.total}개까지 확인했어요'
              : '검사를 시작하지 않았어요',
          style: TextStyle(fontSize: 14.sp, color: grey500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _allOk() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: const BoxDecoration(
            color: primary100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, color: primary600, size: 30.w),
        ),
        SizedBox(height: 14.w),
        Text(
          '모든 링크가 정상이에요',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: grey900,
          ),
        ),
        SizedBox(height: 6.w),
        Text(
          '${state.total}개 링크를 검사했어요',
          style: TextStyle(fontSize: 14.sp, color: grey500),
        ),
      ],
    );
  }

  Widget _brokenList(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.doneText,
          style: TextStyle(
            fontSize: 14.sp,
            color: redError,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10.w),
        SizedBox(
          height: 260.w,
          child: BlocBuilder<LinkCheckCubit, LinkCheckState>(
            builder: (context, currentState) {
              if (currentState.brokenLinks.isEmpty) {
                return Center(
                  child: Text(
                    '모두 정리했어요!',
                    style: TextStyle(fontSize: 14.sp, color: grey500),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: currentState.brokenLinks.length,
                separatorBuilder: (_, __) => SizedBox(height: 6.w),
                itemBuilder: (_, index) {
                  final link = currentState.brokenLinks[index];
                  return _BrokenLinkTile(link: link);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BrokenLinkTile extends StatelessWidget {
  const _BrokenLinkTile({required this.link});

  final BrokenLink link;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F3),
        borderRadius: BorderRadius.circular(10.w),
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
                    fontSize: 13.sp,
                    color: grey800,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.w),
                Text(
                  link.status != null ? 'HTTP ${link.status}' : '연결 실패',
                  style: TextStyle(fontSize: 11.sp, color: grey500),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => context
                .read<LinkCheckCubit>()
                .deleteBrokenLink(link.linkId),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.w),
              ),
              child: Text(
                '삭제',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: redError,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkCheckCta extends StatelessWidget {
  const _LinkCheckCta({required this.state});

  final LinkCheckState state;

  @override
  Widget build(BuildContext context) {
    final isChecking = state.status == LinkCheckStatus.checking ||
        state.status == LinkCheckStatus.initial;

    if (isChecking) {
      return SizedBox(
        width: double.infinity,
        height: 48.w,
        child: OutlinedButton(
          onPressed: () => context.read<LinkCheckCubit>().cancel(),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: BorderSide(color: grey300, width: 1.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.w),
            ),
          ),
          child: Text(
            '중지',
            style: TextStyle(
              color: grey700,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48.w,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.w),
          ),
          shadowColor: Colors.transparent,
        ),
        child: Text(
          '확인',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Pro 계정의 마지막 백업 시각을 한 줄로 조용히 노출.
/// 아직 백업된 적이 없으면 "Pro" 만 표시.
class _ProCaption extends StatefulWidget {
  const _ProCaption();

  @override
  State<_ProCaption> createState() => _ProCaptionState();
}

class _ProCaptionState extends State<_ProCaption> with WidgetsBindingObserver {
  late final SyncRepository _sync = getIt<SyncRepository>();
  DateTime? _lastBackupAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final at = await _sync.getLastBackupAt();
    if (mounted) setState(() => _lastBackupAt = at);
  }

  @override
  Widget build(BuildContext context) {
    final caption = _lastBackupAt == null
        ? 'Pro'
        : 'Pro · 마지막 백업 ${_formatDate(_lastBackupAt!)}';
    return Padding(
      padding: EdgeInsets.only(top: 2.w),
      child: Text(
        caption,
        style: TextStyle(
          fontSize: 12.sp,
          color: primary600,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.month)}/${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

