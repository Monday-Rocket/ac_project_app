import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/folder_view_type_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/home/get_job_list_cubit.dart';
import 'package:ac_project_app/cubits/home_view_cubit.dart';
import 'package:ac_project_app/cubits/links/links_from_selected_job_group_cubit.dart';
import 'package:ac_project_app/cubits/tool_tip/upload_tool_tip_cubit.dart';
import 'package:ac_project_app/enums/navigator_pop_type.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/tool_tip_check.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/page/home/home_page.dart';
import 'package:ac_project_app/ui/page/my_folder/my_folder_page.dart';
import 'package:ac_project_app/ui/page/my_page/my_page.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/scaffold_with_tool_tip.dart';
import 'package:ac_project_app/ui/widget/shape/triangle_painter.dart';
import 'package:ac_project_app/ui/widget/widget_offset.dart';
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
    FolderApi().bulkSave().then((value) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FolderApi().bulkSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = getArguments(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => HomeViewCubit((args['index'] as int?) ?? 0),
        ),
        BlocProvider(
          create: (_) => LinksFromSelectedJobGroupCubit(),
        ),
        BlocProvider<GetFoldersCubit>(
          create: (_) => GetFoldersCubit(),
        ),
        BlocProvider<UploadToolTipCubit>(
          create: (_) => UploadToolTipCubit(uploadToolTipButtonKey),
        ),
      ],
      child: BlocBuilder<HomeViewCubit, int>(
        builder: (context, index) {
          final icons = getBottomIcons(index);

          final bottomItems = [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(2),
                width: 24.w,
                height: 24.h,
                child: icons[0],
              ),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Container(
                key: uploadToolTipButtonKey,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  width: 24.w,
                  height: 24.h,
                  child: icons[1],
                ),
              ),
              label: '업로드',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(2),
                width: 24.w,
                height: 24.h,
                child: icons[2],
              ),
              label: '마이폴더',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(2),
                width: 24.w,
                height: 24.h,
                child: icons[3],
              ),
              label: '마이페이지',
            ),
          ];

          return ScaffoldWithToolTip(
            scaffold: buildBody(index, bottomItems, context),
            tooltip: _buildUploadToolTip(context),
          );
        },
      ),
    );
  }

  BlocBuilder<UploadToolTipCubit, WidgetOffset?> _buildUploadToolTip(
    BuildContext context,
  ) {
    return BlocBuilder<UploadToolTipCubit, WidgetOffset?>(
      builder: (ctx, widgetOffset) {
        if (widgetOffset == null) {
          return const SizedBox.shrink();
        } else {
          if (widgetOffset.visible) {
            Future.delayed(const Duration(seconds: 3), () {
              ctx.read<UploadToolTipCubit>().invisible();
              ToolTipCheck.setBottomUploaded();
            });
          }
          return Positioned(
            left: widgetOffset.getTopMid().dx -
                (Platform.isAndroid ? 181 : 188) / 2,
            bottom: MediaQuery.of(context).size.height -
                widgetOffset.rightTop.dy +
                6.h,
            child: AnimatedOpacity(
              opacity: widgetOffset.visible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(4.r)),
                      color: grey900,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    child: Center(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                        child: const Text(
                          '링크를 빠르게 업로드 할 수 있어요!',
                        ),
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: TrianglePainter(
                      strokeColor: grey900,
                      strokeWidth: 1,
                      paintingStyle: PaintingStyle.fill,
                    ),
                    child: SizedBox(
                      width: 12.w,
                      height: 8.h,
                    ),
                  )
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Scaffold buildBody(
    int index,
    List<BottomNavigationBarItem> bottomItems,
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: index,
        children: <Widget>[
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => GetJobListCubit(),
              ),
              BlocProvider(
                create: (_) => GetUserFoldersCubit(),
              ),
            ],
            child: const HomePage(),
          ),
          const Scaffold(),
          MultiBlocProvider(
            providers: [
              BlocProvider<FolderViewTypeCubit>(
                create: (_) => FolderViewTypeCubit(),
              ),
            ],
            child: const MyFolderPage(),
          ),
          const MyPage(),
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
        onTap: (index) {
          if (index == 0) {
            context.read<LinksFromSelectedJobGroupCubit>().refresh();
            context.read<HomeViewCubit>().moveTo(index);
          } else if (index == 1) {
            ToolTipCheck.setBottomUploaded();
            pushUploadView(context);
          } else if (index == 2) {
            context.read<GetFoldersCubit>().getFolders();
            context.read<HomeViewCubit>().moveTo(index);
          } else {
            context.read<HomeViewCubit>().moveTo(index);
          }
        },
      ),
    );
  }

  void pushUploadView(BuildContext context) {
    Navigator.pushNamed(context, Routes.upload).then(
      (value) => setState(
        () {
          if (NavigatorPopType.saveLink == value) {
            showBottomToast(
              context: context,
              '링크가 저장되었어요!',
              callback: () {
                context.read<GetFoldersCubit>().getFolders();
                context.read<HomeViewCubit>().moveTo(2);
              },
            );
          }
        },
      ),
    );
  }

  List<SvgPicture> getBottomIcons(int index) {
    final enabledIcons = [
      SvgPicture.asset(Assets.images.icHome),
      SvgPicture.asset(Assets.images.icUpload),
      SvgPicture.asset(Assets.images.icMyfolder),
      SvgPicture.asset(Assets.images.icMypage),
    ];

    final disabledIcons = [
      SvgPicture.asset(Assets.images.icHomeDisabled),
      SvgPicture.asset(Assets.images.icUploadDisabled),
      SvgPicture.asset(Assets.images.icMyfolderDisabled),
      SvgPicture.asset(Assets.images.icMypageDisabled),
    ];

    final icons = <SvgPicture>[];

    for (var i = 0; i < 4; i++) {
      if (i == index) {
        icons.add(enabledIcons[i]);
      } else {
        icons.add(disabledIcons[i]);
      }
    }
    return icons;
  }
}
