import 'package:ac_project_app/ui/page/my_folder_page.dart';
import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {

  final textController = TextEditingController();

  final List<Widget> _widgetOptions = <Widget>[
    const MyPage(),
    const MyFolderPage(),
    const FolderPage(),
    const HomePage(),
  ];

  var index = 0;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: _widgetOptions[index],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        selectedFontSize: 16,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        unselectedItemColor: Colors.grey,
        unselectedFontSize: 14,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.ac_unit), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.access_alarm_outlined), label: '마이폴더'),
          BottomNavigationBarItem(icon: Icon(Icons.ac_unit), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.ac_unit), label: '마이폴더'),
        ],
        currentIndex: index,
        onTap: (i) {
          setState(() {
            index = i;
          });
        },
      ),
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class UnknownPage extends StatefulWidget {
  const UnknownPage({super.key});

  @override
  State<UnknownPage> createState() => _UnknownPageState();
}

class _UnknownPageState extends State<UnknownPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}



class FolderPage extends StatefulWidget {
  const FolderPage({super.key});

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

