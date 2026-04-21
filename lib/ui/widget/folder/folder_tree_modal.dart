import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 전체 폴더 트리 조망 모달.
/// 노드 탭 시 해당 폴더의 드릴다운 페이지로 점프하고 모달은 닫힘.
Future<void> showFolderTreeModal(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _FolderTreeSheet(),
  );
}

class _FolderTreeSheet extends StatefulWidget {
  const _FolderTreeSheet();

  @override
  State<_FolderTreeSheet> createState() => _FolderTreeSheetState();
}

class _FolderTreeSheetState extends State<_FolderTreeSheet> {
  final LocalFolderRepository _repo = getIt<LocalFolderRepository>();
  final Set<int> _expanded = {};
  late Future<_TreeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TreeData> _load() async {
    final all = await _repo.getAllFolders();
    final counts = await _repo.getRecursiveLinkCounts();
    final byParent = <int?, List<LocalFolder>>{};
    for (final f in all) {
      byParent.putIfAbsent(f.parentId, () => []).add(f);
    }
    return _TreeData(byParent: byParent, counts: counts);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.7,
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 8.w),
            width: 40.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(Icons.account_tree_outlined,
                    size: 18.sp, color: primary600),
                SizedBox(width: 8.w),
                Text(
                  '전체 폴더 트리',
                  style: TextStyle(
                    color: blackBold,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1.w, color: greyTab),
          Expanded(
            child: FutureBuilder<_TreeData>(
              future: _future,
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildNodes(snap.data!, parentId: null, depth: 0),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNodes(
    _TreeData data, {
    required int? parentId,
    required int depth,
  }) {
    final children = data.byParent[parentId] ?? const <LocalFolder>[];
    final widgets = <Widget>[];
    for (final folder in children) {
      final id = folder.id;
      if (id == null) continue;
      final hasChildren = data.byParent[id]?.isNotEmpty ?? false;
      final isExpanded = _expanded.contains(id);
      final total = data.counts[id] ?? 0;
      widgets.add(
        InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              Routes.folderDrillDown,
              arguments: {'folderId': id},
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 10.w,
              horizontal: 8.w + (depth * 16).w,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: hasChildren
                      ? () {
                          setState(() {
                            if (isExpanded) {
                              _expanded.remove(id);
                            } else {
                              _expanded.add(id);
                            }
                          });
                        }
                      : null,
                  child: SizedBox(
                    width: 20.w,
                    child: hasChildren
                        ? Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.chevron_right,
                            size: 18.sp,
                            color: grey600,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                Icon(
                  Icons.folder,
                  size: 16.sp,
                  color: folder.isClassified ? primary600 : grey600,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: blackBold,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '$total',
                  style: TextStyle(color: greyText, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ),
      );
      if (hasChildren && isExpanded) {
        widgets.addAll(_buildNodes(data, parentId: id, depth: depth + 1));
      }
    }
    return widgets;
  }
}

class _TreeData {
  const _TreeData({required this.byParent, required this.counts});
  final Map<int?, List<LocalFolder>> byParent;
  final Map<int, int> counts;
}
