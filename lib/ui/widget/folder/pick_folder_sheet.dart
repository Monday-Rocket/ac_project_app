import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/recent_folders_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 폴더 선택 모달. 선택된 폴더 id를 반환(null이면 취소).
/// [excludeIds]에 포함된 폴더는 비활성화 표시.
/// [includeUnclassified]가 false면 미분류 폴더를 picker에서 숨김.
Future<int?> showPickFolderSheet({
  required BuildContext context,
  String title = '폴더 선택',
  Set<int> excludeIds = const {},
  bool includeUnclassified = false,
  String? actionLabel,
}) async {
  return showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PickFolderSheet(
      title: title,
      excludeIds: excludeIds,
      includeUnclassified: includeUnclassified,
      actionLabel: actionLabel ?? '선택',
    ),
  );
}

class _PickFolderSheet extends StatefulWidget {
  const _PickFolderSheet({
    required this.title,
    required this.excludeIds,
    required this.includeUnclassified,
    required this.actionLabel,
  });

  final String title;
  final Set<int> excludeIds;
  final bool includeUnclassified;
  final String actionLabel;

  @override
  State<_PickFolderSheet> createState() => _PickFolderSheetState();
}

class _PickFolderSheetState extends State<_PickFolderSheet> {
  final LocalFolderRepository _repo = getIt<LocalFolderRepository>();
  final RecentFoldersRepository _recent = const RecentFoldersRepository();

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  /// 드릴다운 스택 (null = 루트). 현재 보고 있는 부모 폴더 ID.
  final List<int?> _pathStack = <int?>[null];

  List<LocalFolder> _allFolders = const [];
  List<LocalFolder> _recentFolders = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final all = await _repo.getAllFolders();
    final recentIds = await _recent.getRecentIds();
    final byId = {for (final f in all) f.id: f};
    final recentFolders = recentIds
        .map((id) => byId[id])
        .whereType<LocalFolder>()
        .where((f) => widget.includeUnclassified || f.isClassified)
        .toList();
    if (!mounted) return;
    setState(() {
      _allFolders = all;
      _recentFolders = recentFolders;
      _loading = false;
    });
  }

  Iterable<LocalFolder> _visible(Iterable<LocalFolder> folders) {
    return folders.where(
      (f) => widget.includeUnclassified || f.isClassified,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _pick(int? folderId) {
    if (folderId == null) return;
    if (widget.excludeIds.contains(folderId)) return;
    Navigator.pop(context, folderId);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.8,
      child: Column(
        children: [
          // grip
          Container(
            margin: EdgeInsets.only(top: 8.w),
            width: 40.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // title + cancel
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.w, 8.w, 4.w),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: blackBold,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '취소',
                    style: TextStyle(color: grey600, fontSize: 13.sp),
                  ),
                ),
              ],
            ),
          ),
          // search field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: '폴더 검색…',
                prefixIcon: Icon(Icons.search, size: 18.sp, color: grey600),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.w,
                ),
                filled: true,
                fillColor: grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Divider(height: 1, thickness: 1.w, color: greyTab),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _query.isNotEmpty
                    ? _buildSearchResults()
                    : _buildDrilldown(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final q = _query.toLowerCase();
    final matches = _visible(_allFolders)
        .where((f) => f.name.toLowerCase().contains(q))
        .toList();
    if (matches.isEmpty) {
      return Center(
        child: Text(
          '일치하는 폴더가 없습니다',
          style: TextStyle(color: grey600, fontSize: 13.sp),
        ),
      );
    }
    return ListView.separated(
      itemCount: matches.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, thickness: 1.w, color: greyTab),
      itemBuilder: (ctx, i) {
        final f = matches[i];
        return _FolderRow(
          folder: f,
          pathLabel: _pathLabel(f),
          disabled: f.id == null || widget.excludeIds.contains(f.id),
          onTap: () => _pick(f.id),
        );
      },
    );
  }

  Widget _buildDrilldown() {
    final currentParent = _pathStack.last;
    final children = _visible(_allFolders.where(
      (f) => f.parentId == currentParent,
    )).toList();

    return Column(
      children: [
        // 최근 사용 (루트에서만 표시)
        if (currentParent == null && _recentFolders.isNotEmpty)
          _RecentSection(
            folders: _recentFolders,
            pathLabelFor: _pathLabel,
            excludeIds: widget.excludeIds,
            onPick: _pick,
          ),
        // 경로 표시 (드릴다운한 경우)
        if (currentParent != null)
          _PathBar(
            stack: _pathStack,
            nameFor: (id) =>
                _allFolders.firstWhere((f) => f.id == id).name,
            onTapIndex: (i) {
              setState(() {
                _pathStack.removeRange(i + 1, _pathStack.length);
              });
            },
          ),
        Expanded(
          child: children.isEmpty
              ? Center(
                  child: Text(
                    '하위 폴더가 없습니다',
                    style: TextStyle(color: grey600, fontSize: 13.sp),
                  ),
                )
              : ListView.separated(
                  itemCount: children.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, thickness: 1.w, color: greyTab),
                  itemBuilder: (ctx, i) {
                    final f = children[i];
                    final hasChildren = _allFolders.any(
                      (c) => c.parentId == f.id,
                    );
                    return _FolderRow(
                      folder: f,
                      hasChildren: hasChildren,
                      disabled:
                          f.id == null || widget.excludeIds.contains(f.id),
                      onDrillIn: hasChildren
                          ? () {
                              setState(() => _pathStack.add(f.id));
                            }
                          : null,
                      onTap: () => _pick(f.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _pathLabel(LocalFolder folder) {
    final parts = <String>[];
    LocalFolder? cur = folder;
    final byId = {for (final f in _allFolders) f.id: f};
    while (cur != null && cur.parentId != null) {
      cur = byId[cur.parentId];
      if (cur == null) break;
      parts.insert(0, cur.name);
    }
    return parts.join(' > ');
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection({
    required this.folders,
    required this.pathLabelFor,
    required this.excludeIds,
    required this.onPick,
  });

  final List<LocalFolder> folders;
  final String Function(LocalFolder) pathLabelFor;
  final Set<int> excludeIds;
  final void Function(int?) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.w, 16.w, 6.w),
          child: Text(
            '최근 사용',
            style: TextStyle(
              color: grey600,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...folders.map((f) {
          final path = pathLabelFor(f);
          return _FolderRow(
            folder: f,
            pathLabel: path.isEmpty ? null : path,
            disabled: f.id == null || excludeIds.contains(f.id),
            onTap: () => onPick(f.id),
          );
        }),
        Divider(height: 12.w, thickness: 6.w, color: grey100),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 6.w),
          child: Text(
            '전체',
            style: TextStyle(
              color: grey600,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PathBar extends StatelessWidget {
  const _PathBar({
    required this.stack,
    required this.nameFor,
    required this.onTapIndex,
  });

  final List<int?> stack;
  final String Function(int) nameFor;
  final void Function(int) onTapIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      color: grey100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            InkWell(
              onTap: () => onTapIndex(0),
              child: Row(
                children: [
                  Icon(Icons.home, size: 14.sp, color: grey600),
                  SizedBox(width: 4.w),
                  Text(
                    '루트',
                    style: TextStyle(color: grey600, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            for (int i = 1; i < stack.length; i++) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Icon(Icons.chevron_right, size: 14.sp, color: grey600),
              ),
              InkWell(
                onTap: () => onTapIndex(i),
                child: Text(
                  nameFor(stack[i]!),
                  style: TextStyle(
                    color: i == stack.length - 1 ? blackBold : grey600,
                    fontSize: 12.sp,
                    fontWeight:
                        i == stack.length - 1 ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.folder,
    this.pathLabel,
    this.hasChildren = false,
    this.disabled = false,
    this.onTap,
    this.onDrillIn,
  });

  final LocalFolder folder;
  final String? pathLabel;
  final bool hasChildren;
  final bool disabled;
  final VoidCallback? onTap;
  final VoidCallback? onDrillIn;

  @override
  Widget build(BuildContext context) {
    final color = disabled ? grey300 : blackBold;
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
        leading: Icon(
          folder.isClassified ? Icons.folder : Icons.inbox,
          size: 18.sp,
          color: folder.isClassified ? primary600 : grey600,
        ),
        title: Text(
          folder.name,
          style: TextStyle(
            color: color,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: pathLabel == null || pathLabel!.isEmpty
            ? null
            : Text(
                pathLabel!,
                style: TextStyle(color: greyText, fontSize: 11.sp),
              ),
        trailing: hasChildren
            ? IconButton(
                onPressed: onDrillIn,
                icon: Icon(
                  Icons.chevron_right,
                  size: 20.sp,
                  color: grey600,
                ),
                tooltip: '하위 폴더',
              )
            : null,
        onTap: disabled ? null : onTap,
      ),
    );
  }
}
