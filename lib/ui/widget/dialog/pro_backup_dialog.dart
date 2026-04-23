import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/auth/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Free → Pro 전환 시 전체 업로드 진행을 보여주는 모달 로딩 Dialog.
///
/// AuthState.backupPhase 변화를 구독해 텍스트를 갱신한다.
/// - preparing: "업로드 준비 중이에요"
/// - uploadingFolders: "폴더를 업로드하고 있어요"
/// - uploadingLinks: "링크를 업로드하고 있어요"
/// - done/failed: 토스트로 결과 표시 후 Navigator.pop.
///
/// 업로드 중에는 뒤로가기/배경 탭으로 닫을 수 없다.
class ProBackupDialog extends StatelessWidget {
  const ProBackupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (prev, curr) => prev.backupPhase != curr.backupPhase,
      builder: (context, state) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.w),
            ),
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SizedBox(
              width: width - 48.w,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 24.w, 20.w, 24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 56.w,
                      height: 56.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 4.w,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(primary600),
                      ),
                    ),
                    SizedBox(height: 20.w),
                    Text(
                      _titleFor(state.backupPhase),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: grey900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 8.w),
                    Text(
                      '잠시만 기다려 주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _titleFor(ProBackupPhase phase) {
    switch (phase) {
      case ProBackupPhase.preparing:
        return '업로드 준비 중이에요';
      case ProBackupPhase.uploadingFolders:
        return '폴더를 업로드하고 있어요';
      case ProBackupPhase.uploadingLinks:
        return '링크를 업로드하고 있어요';
      case ProBackupPhase.done:
        return '업로드를 마무리하고 있어요';
      case ProBackupPhase.failed:
        return '업로드에 문제가 생겼어요';
      case ProBackupPhase.idle:
        return '';
    }
  }
}
