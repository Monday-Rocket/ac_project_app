import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folder_drill_down_cubit.dart';
import 'package:ac_project_app/cubits/folders/folder_drill_down_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 중첩 폴더 드릴다운 페이지.
/// 상단 브레드크럼 + 하위 폴더 섹션 + 이 폴더의 직접 링크 섹션을 동시에 표시.
/// arguments: { 'folderId': int }
class FolderDrillDownPage extends StatelessWidget {
  const FolderDrillDownPage({super.key, required this.folderId});

  final int folderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FolderDrillDownCubit(folderId: folderId),
      child: const _FolderDrillDownView(),
    );
  }
}

class _FolderDrillDownView extends StatelessWidget {
  const _FolderDrillDownView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: blackBold),
        title: BlocBuilder<FolderDrillDownCubit, FolderDrillDownState>(
          builder: (context, state) {
            if (state is FolderDrillDownLoaded) {
              return Text(
                state.currentFolder?.name ?? '',
                style: TextStyle(
                  color: blackBold,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      body: BlocBuilder<FolderDrillDownCubit, FolderDrillDownState>(
        builder: (context, state) {
          if (state is FolderDrillDownLoading || state is FolderDrillDownInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FolderDrillDownError) {
            return Center(
              child: Text(
                '불러오지 못했습니다',
                style: TextStyle(color: grey600, fontSize: 14.sp),
              ),
            );
          }
          if (state is FolderDrillDownLoaded) {
            return RefreshIndicator(
              color: primary600,
              onRefresh: () => context.read<FolderDrillDownCubit>().refresh(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Breadcrumb(breadcrumb: state.breadcrumb),
                  ),
                  if (state.childFolders.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        label: '하위 폴더 (${state.childFolders.length})',
                      ),
                    ),
                    SliverList.separated(
                      itemCount: state.childFolders.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1.w,
                        color: greyTab,
                      ),
                      itemBuilder: (ctx, i) {
                        return _ChildFolderTile(folder: state.childFolders[i]);
                      },
                    ),
                  ],
                  if (state.directLinks.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        label: '이 폴더의 링크 (${state.directLinks.length})',
                      ),
                    ),
                    SliverList.separated(
                      itemCount: state.directLinks.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1.w,
                        color: greyTab,
                      ),
                      itemBuilder: (ctx, i) {
                        return _LinkTile(link: state.directLinks[i]);
                      },
                    ),
                  ],
                  if (state.childFolders.isEmpty && state.directLinks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          '이 폴더는 비어있습니다',
                          style: TextStyle(
                            color: grey300,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(child: SizedBox(height: 32.w)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.breadcrumb});

  final List<Folder> breadcrumb;

  @override
  Widget build(BuildContext context) {
    if (breadcrumb.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.w),
      color: grey100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < breadcrumb.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16.sp,
                    color: grey600,
                  ),
                ),
              InkWell(
                onTap: i == breadcrumb.length - 1
                    ? null
                    : () {
                        _navigateToFolder(context, breadcrumb[i].id!);
                      },
                child: Text(
                  breadcrumb[i].name ?? '',
                  style: TextStyle(
                    color: i == breadcrumb.length - 1 ? blackBold : grey600,
                    fontSize: 13.sp,
                    fontWeight: i == breadcrumb.length - 1
                        ? FontWeight.w600
                        : FontWeight.w500,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.w),
      child: Text(
        label,
        style: TextStyle(
          color: grey600,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _ChildFolderTile extends StatelessWidget {
  const _ChildFolderTile({required this.folder});
  final Folder folder;

  @override
  Widget build(BuildContext context) {
    final total = folder.linksTotal ?? folder.links ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: primary100,
          borderRadius: BorderRadius.circular(10.w),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.folder, size: 20.sp, color: primary600),
      ),
      title: Text(
        folder.name ?? '',
        style: TextStyle(
          color: blackBold,
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '링크 ${addCommasFrom(total)}개',
        style: TextStyle(color: greyText, fontSize: 12.sp),
      ),
      trailing: Icon(Icons.chevron_right, color: grey600, size: 20.sp),
      onTap: () => _navigateToFolder(context, folder.id!),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.link});
  final Link link;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
      leading: _LinkThumbnail(link: link),
      title: Text(
        (link.title?.isNotEmpty ?? false) ? link.title! : (link.url ?? ''),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: blackBold,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        link.url ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: greyText, fontSize: 11.sp),
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.linkDetail,
          arguments: {'link': link},
        );
      },
    );
  }
}

class _LinkThumbnail extends StatelessWidget {
  const _LinkThumbnail({required this.link});
  final Link link;

  @override
  Widget build(BuildContext context) {
    final hasImage = link.image?.isNotEmpty ?? false;
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: grey100,
        borderRadius: BorderRadius.circular(8.w),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              link.image!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Icon(Icons.link, size: 20.sp, color: grey600);
}

void _navigateToFolder(BuildContext context, int folderId) {
  Navigator.pushNamed(
    context,
    Routes.folderDrillDown,
    arguments: {'folderId': folderId},
  );
}
