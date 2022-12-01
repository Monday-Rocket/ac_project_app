import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Folder {
  final String name;
  final String imageLink;

  Folder({
    required this.name,
    required this.imageLink,
  });
}

class UploadPage extends StatefulWidget {
  static String get routeName => 'test_screen';

  UploadPage({Key? key}) : super(key: key);

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage>
    with SingleTickerProviderStateMixin {
  List<Folder> links = [
    Folder(
        name: '123',
        imageLink:
            'https://cdn.pixabay.com/photo/2017/02/20/18/03/cat-2083492_1280.jpg'),
    Folder(
        name: '1234',
        imageLink:
            'https://cdn.pixabay.com/photo/2017/02/20/18/03/cat-2083492_1280.jpg'),
    Folder(
        name: '644',
        imageLink:
            'https://cdn.pixabay.com/photo/2017/02/20/18/03/cat-2083492_1280.jpg'),
    Folder(
        name: '523',
        imageLink:
            'https://cdn.pixabay.com/photo/2017/02/20/18/03/cat-2083492_1280.jpg'),
    Folder(
        name: '123',
        imageLink:
            'https://cdn.pixabay.com/photo/2017/02/20/18/03/cat-2083492_1280.jpg'),
    Folder(
        name: '1234',
        imageLink:
            'https://cdn.pixabay.com/photo/2017/02/20/18/03/cat-2083492_1280.jpg'),
    Folder(
        name: '644',
        imageLink:
            'https://cdn.pixabay.com/photo/2017/02/20/18/03/cat-2083492_1280.jpg'),
    Folder(
        name: '523',
        imageLink:
            'https://cdn.pixabay.com/photo/2017/02/20/18/03/cat-2083492_1280.jpg'),
  ];
  late TabController _tabController;
  bool isFilled = false;

  @override
  void initState() {
    _tabController = TabController(length: links.length, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _linkController = TextEditingController();
    TextEditingController _commentController = TextEditingController();

    return BlocProvider<GetFoldersCubit>(
      create: (_) => GetFoldersCubit(),
      child: Scaffold(
        bottomSheet: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24, bottom: 16),
          child: ElevatedButton(
            onPressed: () {},
            child: Text(
              '등록완료',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
                elevation: 0,
                fixedSize: Size(MediaQuery.of(context).size.width - 48, 56),
                backgroundColor: isFilled ? primary600 : primary200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                )),
          ),
        ),
        appBar: AppBar(
          title: Text('업로드'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: grey900,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 20.0,
            left: 24,
            right: 24,
          ),
          child: SafeArea(
            child: ListView(
              children: [
                Container(
                  margin: EdgeInsets.only(
                    bottom: 14,
                  ),
                  child: Text(
                    '폴더 선택',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextFormField(
                  controller: _linkController,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                  ),
                  decoration: InputDecoration(
                    hintText: '링크를 여기에 불러주세요',
                    filled: true,
                    fillColor: grey100,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  minLines: 3,
                  maxLines: null,
                ),
                Container(
                  margin: EdgeInsets.only(
                    top: 35,
                    bottom: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '폴더 선택',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.add),
                      )
                    ],
                  ),
                ),
                TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: grey200,
                  ),
                  isScrollable: true,
                  controller: _tabController,
                  tabs: links.map((e) {
                    return Tab(
                      height: 140,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              child: Image.network(
                                e.imageLink,
                                height: 95,
                                width: 95,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Text(
                              e.name,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Container(
                  margin: EdgeInsets.only(
                    top: 35,
                    bottom: 14,
                  ),
                  child: Text(
                    '링크 코멘트',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextFormField(
                  controller: _commentController,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                  ),
                  decoration: InputDecoration(
                    hintText: '저장한 링크에 대해 간단하게 메모해보세요',
                    filled: true,
                    fillColor: grey100,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  minLines: 3,
                  maxLines: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
