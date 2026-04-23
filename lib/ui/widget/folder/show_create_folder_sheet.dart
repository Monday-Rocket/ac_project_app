import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/create_folder_result.dart';
import 'package:ac_project_app/cubits/folders/local_folders_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/ui/widget/folder/pick_folder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 루트 또는 특정 부모 아래에 새 폴더를 만드는 바텀 시트.
/// 취소=null, 생성 성공=새 폴더 id 반환.
Future<int?> showCreateFolderSheet(
  BuildContext context, {
  int? initialParentId,
  bool allowParentPick = true,
}) async {
  // Capture the cubit before entering the new route so the sheet can use it
  // even though showModalBottomSheet opens in a separate navigator scope.
  final cubit = context.read<LocalFoldersCubit>();
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _CreateFolderSheet(
        initialParentId: initialParentId,
        allowParentPick: allowParentPick,
      ),
    ),
  );
}

class _CreateFolderSheet extends StatefulWidget {
  const _CreateFolderSheet({
    required this.initialParentId,
    required this.allowParentPick,
  });

  final int? initialParentId;
  final bool allowParentPick;

  @override
  State<_CreateFolderSheet> createState() => _CreateFolderSheetState();
}

class _CreateFolderSheetState extends State<_CreateFolderSheet> {
  final _controller = TextEditingController();
  int? _parentId;
  String _parentPath = '루트';
  String? _errorText;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _parentId = widget.initialParentId;
    _loadParentPath();
    _controller.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    // 버튼 활성화 재계산용 setState — TextEditingController 변화 감지.
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadParentPath() async {
    if (_parentId == null) {
      if (!mounted) return;
      setState(() => _parentPath = '루트');
      return;
    }
    final repo = getIt<LocalFolderRepository>();
    final crumbs = await repo.getBreadcrumb(_parentId!);
    if (!mounted) return;
    setState(() {
      _parentPath = crumbs.map((f) => f.name).join(' > ');
    });
  }

  Future<void> _onParentTap() async {
    final picked = await showPickFolderSheet(
      context: context,
      title: '상위 폴더 선택',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _parentId = picked;
      _errorText = null;
    });
    await _loadParentPath();
  }

  Future<void> _onSubmit() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorText = '폴더 이름을 입력해주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final cubit = context.read<LocalFoldersCubit>();
    final result = await cubit.createFolder(raw, parentId: _parentId);
    if (!mounted) return;

    switch (result) {
      case Created(:final id):
        Navigator.pop(context, id);
      case DuplicateSibling():
        setState(() {
          _errorText =
              '같은 위치에 이미 같은 이름의 폴더가 있어요. 다른 이름을 입력해주세요.';
          _submitting = false;
        });
      case ParentMissing():
        setState(() {
          _errorText = '상위 폴더를 찾을 수 없어요. 다시 선택해주세요.';
          _submitting = false;
        });
      case CreateFolderFailed():
        setState(() {
          _errorText = '폴더를 만들지 못했어요. 잠시 후 다시 시도해주세요.';
          _submitting = false;
        });
    }
  }

  bool get _canSubmit {
    final text = _controller.text;
    return text.trim().isNotEmpty &&
        !_submitting &&
        _errorText == null &&
        text.length <= 20;
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onNameChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.w),
            topRight: Radius.circular(20.w),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: 30.w,
            left: 24.w,
            right: 24.w,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                (Platform.isAndroid
                    ? MediaQuery.of(context).padding.bottom
                    : 16.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: 28.w),
              if (widget.allowParentPick) _buildParentRow(),
              if (widget.allowParentPick) SizedBox(height: 20.w),
              _buildNameField(),
              SizedBox(height: 40.w),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Center(
          child: Text(
            '새로운 폴더',
            style: TextStyle(
              color: blackBold,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: InkWell(
            key: const Key('create_folder_done_text'),
            onTap: _canSubmit ? _onSubmit : null,
            child: Text(
              '완료',
              style: TextStyle(
                color: _canSubmit ? grey800 : grey300,
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParentRow() {
    return InkWell(
      key: const Key('create_folder_parent_row'),
      onTap: _onParentTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: greyTab, width: 1.w),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.folder, size: 16.sp, color: primary600),
            SizedBox(width: 8.w),
            Text(
              '상위 폴더',
              style: TextStyle(
                color: grey600,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                _parentPath,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: blackBold,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right, size: 18.sp, color: grey600),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      key: const Key('create_folder_name_field'),
      controller: _controller,
      autofocus: true,
      maxLength: 20,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
        color: grey800,
      ),
      cursorColor: primary600,
      decoration: InputDecoration(
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primary800, width: 2.w),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: greyTab, width: 2.w),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: redError, width: 2.w),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: redError, width: 2.w),
        ),
        counterText: '',
        errorText: _errorText,
        errorStyle: const TextStyle(color: redError),
        hintText: '새로운 폴더 이름',
        hintStyle: TextStyle(
          color: grey400,
          fontSize: 17.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      onChanged: (_) {
        if (_errorText != null) {
          setState(() => _errorText = null);
        }
      },
      onFieldSubmitted: (_) {
        if (_canSubmit) _onSubmit();
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      key: const Key('create_folder_submit'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(55.w),
        backgroundColor: _canSubmit ? primary600 : secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.w),
        ),
        shadowColor: Colors.transparent,
      ),
      onPressed: _canSubmit ? _onSubmit : null,
      child: _submitting
          ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              '폴더 생성하기',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
}
