import 'package:ac_project_app/cubits/folders/folder_drill_down_cubit.dart';
import 'package:ac_project_app/cubits/folders/folder_drill_down_state.dart';
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late LocalFolderRepository folderRepo;
  late LocalLinkRepository linkRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper.createForTest();
    folderRepo = LocalFolderRepository(databaseHelper: databaseHelper);
    linkRepo = LocalLinkRepository(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    await databaseHelper.deleteDatabase();
    await databaseHelper.close();
  });

  Future<int> makeFolder(String name, {int? parentId}) async {
    final now = DateTime.now().toIso8601String();
    return folderRepo.createFolder(
      LocalFolder(
        name: name,
        parentId: parentId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> makeLink(int folderId, String url) async {
    final now = DateTime.now().toIso8601String();
    await linkRepo.createLink(
      LocalLink(
        folderId: folderId,
        url: url,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  test('loads breadcrumb, child folders, and direct links for a folder',
      () async {
    final workId = await makeFolder('일');
    final devId = await makeFolder('개발', parentId: workId);
    await makeFolder('React', parentId: devId);
    await makeFolder('Vue', parentId: devId);
    await makeLink(devId, 'https://a');
    await makeLink(devId, 'https://b');

    final cubit = FolderDrillDownCubit(
      folderId: devId,
      folderRepo: folderRepo,
      linkRepo: linkRepo,
      autoLoad: false,
    );
    await cubit.load();

    expect(cubit.state, isA<FolderDrillDownLoaded>());
    final state = cubit.state as FolderDrillDownLoaded;
    expect(state.breadcrumb.map((f) => f.name).toList(), ['일', '개발']);
    expect(state.childFolders.map((f) => f.name).toSet(), {'React', 'Vue'});
    expect(state.directLinks.length, 2);
  });

  test('child folders carry recursive link counts', () async {
    final workId = await makeFolder('일');
    final devId = await makeFolder('개발', parentId: workId);
    final reactId = await makeFolder('React', parentId: devId);
    await makeLink(devId, 'https://a');
    await makeLink(reactId, 'https://r1');
    await makeLink(reactId, 'https://r2');

    final cubit = FolderDrillDownCubit(
      folderId: workId,
      folderRepo: folderRepo,
      linkRepo: linkRepo,
      autoLoad: false,
    );
    await cubit.load();

    final state = cubit.state as FolderDrillDownLoaded;
    final dev = state.childFolders.firstWhere((f) => f.name == '개발');
    expect(dev.linksTotal, 3); // 개발(1) + React(2)
  });
}
