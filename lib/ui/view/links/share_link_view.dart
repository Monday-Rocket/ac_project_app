import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/const/strings.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_folder_cubit.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/buttons/upload_button.dart';
import 'package:ac_project_app/ui/widget/dialog/bottom_dialog.dart';
import 'package:ac_project_app/ui/widget/dialog/center_dialog.dart';
import 'package:ac_project_app/ui/widget/link_hero.dart';
import 'package:ac_project_app/util/get_arguments.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/number_commas.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';

class ShareLinkView extends StatefulWidget {
  const ShareLinkView({super.key});

  @override
  State<ShareLinkView> createState() => _ShareLinkViewState();
}

class _ShareLinkViewState extends State<ShareLinkView> {
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final arguments = getArguments(context);
    final folder = arguments['folder'] as Folder;
    final isAdmin = arguments['isAdmin'] as bool;
    final links = <Link>[];

    return BlocProvider(
      create: (_) => LinksFromSelectedFolderCubit(folder, 0),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocBuilder<LinksFromSelectedFolderCubit, LinkListState>(
            builder: (cubitContext, state) {
              return Stack(
                children: [
                  NotificationListener<ScrollEndNotification>(
                    onNotification: (scrollEnd) {
                      final metrics = scrollEnd.metrics;
                      if (metrics.atEdge && metrics.pixels != 0) {
                        context.read<LinksFromSelectedFolderCubit>().loadMore();
                      }
                      return true;
                    },
                    child: CustomScrollView(
                      slivers: [
                        buildTopAppBar(context, folder, isAdmin),
                        buildTitleBar(folder),
                        buildContentsCountText(state, folder.membersCount),
                        SearchBar(),
                        BodyList(
                          folder: folder,
                          width: MediaQuery.of(context).size.width,
                          context: context,
                          totalLinks: links,
                          state: state,
                          foldersContext: context,
                        )
                      ],
                    ),
                  ),
                  FloatingUploadButton(
                    context,
                    callback: () {
                      links.clear();
                      context.read<LinksFromSelectedFolderCubit>().refresh();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget BodyList({
    required Folder folder,
    required double width,
    required BuildContext context,
    required List<Link> totalLinks,
    required LinkListState state,
    required BuildContext foldersContext,
  }) {
    if (folder.links == 0) {
      return buildEmptyList(context);
    } else {
      if (state is LinkListLoadedState) {
        final links = state.links;
        totalLinks.addAll(links);
      }

      return SlidableAutoCloseBehavior(
        child: SliverGrid(
          delegate: SliverChildBuilderDelegate((context, index) {
            return LinkItem(
              context,
              totalLinks[index],
              totalLinks,
              foldersContext,
              folder,
              index,
              width,
            );
          }, childCount: totalLinks.length),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
        ),
      );
    }
  }

  Widget LinkItem(
    BuildContext context,
    Link link,
    List<Link> totalLinks,
    BuildContext foldersContext,
    Folder folder,
    int index,
    double width,
  ) {
    final isOdd = index.isOdd;
    return Padding(
      padding: EdgeInsets.only(left: isOdd ? 0 : 24.w, right: isOdd ? 24.w : 0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.linkDetail,
            arguments: {
              'link': link,
              'isMine': true,
              'visible': folder.visible,
            },
          ).then((result) {
            Log.i(result);
            if (result == 'changed') {
              // update
              totalLinks.clear();

              foldersContext.read<GetFoldersCubit>().getFolders();
              context.read<LinksFromSelectedFolderCubit>().getSelectedLinks(folder, 0);
            } else if (result == 'deleted') {
              Navigator.pop(context);
            }
          });
        },
        child: buildBodyListItem(width, link, isOdd),
      ),
    );
  }

  Widget buildBodyListItem(double width, Link link, bool isOdd) {
    return Column(
      crossAxisAlignment: isOdd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        LinkHero(
          tag: 'linkImage${link.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.all(
              Radius.circular(7.w),
            ),
            child: ColoredBox(
              color: grey100,
              child: link.image != null && link.image!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: link.image ?? '',
                      imageBuilder: (context, imageProvider) => Container(
                        width: width * (152 / 375),
                        height: width * (101 / 375),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) {
                        return SizedBox(
                          width: width * (152 / 375),
                          height: width * (101 / 375),
                        );
                      },
                    )
                  : SizedBox(width: width * (152 / 375), height: width * (101 / 375)),
            ),
          ),
        ),
        16.verticalSpace,
        const Row(),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            152.horizontalSpace,
            Text(
              link.title ?? '',
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: blackBold,
                overflow: TextOverflow.ellipsis,
                height: 19 / 16,
                letterSpacing: -0.2,
              ),
            ),
            5.verticalSpace,
            Text(
              makeLinkTimeString(link.time ?? ''),
              style: TextStyle(
                color: grey400,
                fontSize: 12.sp,
                letterSpacing: -0.2.w,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildEmptyList(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.width / 3),
        child: Center(
          child: Text(
            emptyLinksString,
            style: TextStyle(
              color: grey300,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildContentsCountText(LinkListState state, int? membersCount) {
    final count = (state is LinkListLoadedState) ? state.totalCount : 0;
    final members = membersCount ?? 0;
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(left: 24.w, top: 3.w),
        child: Row(
          children: [
            Text(
              '링크 ${addCommasFrom(count)}개',
              style: TextStyle(
                color: greyText,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
            8.horizontalSpace,
            Container(
              width: 1,
              height: 10,
              color: grey300,
            ),
            8.horizontalSpace,
            Text(
              '$members명의 멤버',
              style: TextStyle(
                color: greyText,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTitleBar(Folder folder) {
    final classified = folder.isClassified ?? true;
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(left: 24.w, right: 12.w, top: 10.w),
        child: Row(
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: 250.w,
              ),
              child: Text(
                classified ? folder.name! : '미분류',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30.sp,
                  height: 36 / 30,
                ),
              ),
            ),
            if (!(folder.visible ?? false))
              Container(
                margin: EdgeInsets.only(left: 8.w),
                child: Assets.images.icLockWebp.image(width: 24.w, height: 24.w, fit: BoxFit.cover),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget buildTopAppBar(
    BuildContext context,
    Folder folder,
    bool isAdmin,
  ) {
    return SliverAppBar(
      pinned: true,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: SvgPicture.asset(
          Assets.images.icBack,
          width: 24.w,
          height: 24.w,
          fit: BoxFit.cover,
        ),
        color: grey900,
        padding: EdgeInsets.only(left: 20.w, right: 8.w),
      ),
      leadingWidth: 44.w,
      toolbarHeight: 48.w,
      actions: [
        InkWell(
          onTap: () {
            showInviteDialog(context);
          },
          child: Container(
            padding: EdgeInsets.all(4.w),
            child: SvgPicture.asset(
              Assets.images.inviteUser,
              width: 24.w,
              height: 24.w,
            ),
          ),
        ),
        InkWell(
          onTap: () {
            showSharedFolderOptionsDialog(context, folder, isAdmin: isAdmin);
          },
          child: Container(
            margin: EdgeInsets.only(right: 20.w),
            padding: EdgeInsets.all(4.w),
            child: SvgPicture.asset(
              Assets.images.more,
              width: 25.w,
              height: 25.w,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
        ),
      ),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  Widget SearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: grey100,
          borderRadius: BorderRadius.all(Radius.circular(7.w)),
        ),
        margin: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 30,
        ),
        height: 36,
        child: Center(
          child: TextField(
            textAlignVertical: TextAlignVertical.center,
            controller: textController,
            cursorColor: grey800,
            autofocus: true,
            style: TextStyle(
              color: grey800,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              // onTapSearch(isMine, context);
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              icon: Container(
                margin: const EdgeInsets.only(left: 10),
                child: Assets.images.folderSearchIcon.image(
                  width: 18.w,
                  height: 18.w,
                  fit: BoxFit.cover,
                ),
              ),
              hintStyle: TextStyle(
                fontSize: 14.sp,
                letterSpacing: -0.1.w,
                height: 18 / 14,
                color: lightGrey700,
              ),
              contentPadding: EdgeInsets.only(
                right: 10.w,
                top: 9.w,
                bottom: 9.w,
              ),
              suffixIcon: InkWell(
                onTap: () {
                  textController.text = '';
                },
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  color: grey400,
                  size: 20.w,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
