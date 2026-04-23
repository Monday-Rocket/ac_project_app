import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 오프라인 감지 시 노출되는 안내 Dialog.
/// Pro 사용자가 앱 진입 또는 쓰기 도중 네트워크가 닿지 않을 때 1회 표시.
///
/// [SyncRepository.offlineNotifier] 가 true 로 전환되는 시점에 HomeView 가 호출한다.
/// "확인"으로 닫을 수 있으며, 같은 세션에서 중복 노출되지 않도록 HomeView 가 flag 로 관리.
class OfflineDialog extends StatelessWidget {
  const OfflineDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const OfflineDialog(),
    );
  }

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
        width: width - 48.w,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 24.w, 20.w, 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 22.sp,
                    color: primary600,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '인터넷 연결이 필요해요',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: grey900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.w),
              Text(
                'Pro 기능은 클라우드 동기화를 사용해요.\n'
                '네트워크 상태를 확인한 뒤 다시 시도해 주세요.',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: grey700,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.w),
              SizedBox(
                height: 48.w,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                  ),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
