# 프로젝트 아키텍처

링크풀 앱의 아키텍처 및 설계 패턴 문서입니다.

## 목차

1. [개요](#개요)
2. [아키텍처 패턴](#아키텍처-패턴)
3. [디렉토리 구조](#디렉토리-구조)
4. [상태 관리](#상태-관리)
5. [의존성 주입](#의존성-주입)
6. [데이터 레이어](#데이터-레이어)
7. [모델 레이어](#모델-레이어)
8. [UI 레이어](#ui-레이어)
9. [네이밍 규칙](#네이밍-규칙)

---

## 개요

링크풀은 **BLoC(Cubit) 패턴**과 **Clean Architecture** 원칙을 기반으로 설계되었습니다.

### 기술 스택

| 영역 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.38.6 |
| 상태 관리 | flutter_bloc (Cubit) |
| 의존성 주입 | get_it |
| 로컬 DB | sqflite |
| 로컬 저장소 | shared_preferences |
| 코드 생성 | freezed, json_serializable, flutter_gen |

---

## 아키텍처 패턴

### 레이어 구조

```
┌─────────────────────────────────────┐
│           UI Layer                  │
│     (Pages, Views, Widgets)         │
├─────────────────────────────────────┤
│         State Management            │
│           (Cubits)                  │
├─────────────────────────────────────┤
│         Data Layer                  │
│     (Local DB, Providers)           │
├─────────────────────────────────────┤
│         Model Layer                 │
│    (Entities, DTOs, Results)        │
└─────────────────────────────────────┘
```

### 데이터 흐름

```
UI → Cubit → LocalRepository → Model → Cubit (State) → UI
```

1. **UI**가 사용자 액션을 **Cubit**에 전달
2. **Cubit**이 **LocalRepository**를 호출
3. **LocalRepository**가 로컬 DB에서 데이터를 가져와 **Model**로 변환
4. **Cubit**이 **State**를 업데이트
5. **UI**가 State 변화를 감지하고 다시 렌더링

---

## 디렉토리 구조

```
lib/
├── const/              # 상수 정의
│   ├── colors.dart     # 색상 상수
│   ├── consts.dart     # 일반 상수
│   └── strings.dart    # 문자열 상수
│
├── cubits/             # 상태 관리 (BLoC/Cubit)
│   ├── common/         # 공통 (ButtonStateCubit)
│   ├── feed/           # 피드 관련
│   ├── folders/        # 폴더 관련
│   ├── links/          # 링크 관련
│   └── ...
│
├── di/                 # 의존성 주입
│   └── set_up_get_it.dart
│
├── gen/                # 자동 생성 파일
│   ├── assets.gen.dart # flutter_gen 에셋
│   └── fonts.gen.dart  # flutter_gen 폰트
│
├── models/             # 데이터 모델
│   ├── folder/         # 폴더 모델
│   ├── link/           # 링크 모델
│   ├── local/          # 로컬 DB 모델
│   └── ...
│
├── provider/           # 데이터 제공자
│   ├── local/          # 로컬 Repository
│   │   ├── local_folder_repository.dart
│   │   ├── local_link_repository.dart
│   │   └── ...
│   └── ...
│
├── ui/                 # UI 컴포넌트
│   ├── page/           # 페이지 (전체 화면)
│   ├── view/           # 뷰 (화면 일부)
│   └── widget/         # 재사용 위젯
│
├── util/               # 유틸리티
│   ├── date_utils.dart
│   ├── string_utils.dart
│   └── ...
│
├── main.dart           # 앱 진입점
├── routes.dart         # 라우팅 설정
└── initial_settings.dart # 초기 설정
```

---

## 상태 관리

### Cubit 패턴

flutter_bloc의 **Cubit**을 사용하여 상태를 관리합니다.

#### 기본 구조

```dart
// State 정의
abstract class FoldersState {}

class FolderInitialState extends FoldersState {}
class FolderLoadingState extends FoldersState {}
class FolderLoadedState extends FoldersState {
  final List<Folder> folders;
  final String totalLinksText;
  final int addedLinksCount;

  FolderLoadedState(this.folders, this.totalLinksText, this.addedLinksCount);
}
class FolderErrorState extends FoldersState {
  final String message;
  FolderErrorState(this.message);
}
```

```dart
// Cubit 구현
class GetFoldersCubit extends Cubit<FoldersState> {
  GetFoldersCubit() : super(FolderInitialState()) {
    getFolders();
  }

  final LocalFolderRepository folderRepo = getIt();

  Future<void> getFolders() async {
    emit(FolderLoadingState());

    try {
      final folders = await folderRepo.getAllFolders();
      emit(FolderLoadedState(folders, ...));
    } catch (e) {
      emit(FolderErrorState(e.toString()));
    }
  }
}
```

#### UI에서 사용

```dart
BlocBuilder<GetFoldersCubit, FoldersState>(
  builder: (context, state) {
    if (state is FolderLoadingState) {
      return LoadingWidget();
    }
    if (state is FolderLoadedState) {
      return FolderListView(folders: state.folders);
    }
    if (state is FolderErrorState) {
      return ErrorWidget(message: state.message);
    }
    return Container();
  },
)
```

### Cubit 위치

| 디렉토리 | 역할 |
|---------|------|
| `cubits/common/` | 공통 (ButtonStateCubit) |
| `cubits/folders/` | 폴더 CRUD, 선택, 공유 |
| `cubits/links/` | 링크 CRUD, 검색, 업로드 |
| `cubits/feed/` | 피드 뷰 관리 |

---

## 의존성 주입

### get_it 설정

`lib/di/set_up_get_it.dart`에서 의존성을 등록합니다.

```dart
final getIt = GetIt.instance;

void locator() {
  final databaseHelper = DatabaseHelper.instance;

  getIt
    // Local Repositories (오프라인 모드 핵심)
    ..registerLazySingleton(() => databaseHelper)
    ..registerLazySingleton(
      () => LocalFolderRepository(databaseHelper: databaseHelper),
    )
    ..registerLazySingleton(
      () => LocalLinkRepository(databaseHelper: databaseHelper),
    )
    ..registerLazySingleton(
      () => LocalBulkRepository(databaseHelper: databaseHelper),
    )

    // Manager
    ..registerLazySingleton(AppPauseManager.new);
}
```

### 사용법

```dart
// Cubit에서
final LocalFolderRepository folderRepo = getIt();

// 또는
final repo = getIt<LocalFolderRepository>();
```

---

## 데이터 레이어

### 로컬 Repository 구조

```dart
class LocalFolderRepository {
  final DatabaseHelper _databaseHelper;

  LocalFolderRepository({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  Future<List<LocalFolder>> getAllFolders() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('folders', orderBy: 'created_at DESC');
    return maps.map(LocalFolder.fromMap).toList();
  }

  Future<int> createFolder(LocalFolder folder) async {
    final db = await _databaseHelper.database;
    return db.insert('folders', folder.toMap());
  }

  Future<int> updateFolder(LocalFolder folder) async {
    final db = await _databaseHelper.database;
    return db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await _databaseHelper.database;
    return db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }
}
```

---

## 모델 레이어

### freezed + json_serializable

```dart
@freezed
class Folder with _$Folder {
  const factory Folder({
    int? id,
    String? name,
    String? thumbnail,
    bool? visible,
    int? links,
    String? time,
  }) = _Folder;

  factory Folder.fromJson(Map<String, dynamic> json) =>
      _$FolderFromJson(json);
}
```

### 코드 생성

```bash
# 모델 변경 후 실행
fvm dart run build_runner build --delete-conflicting-outputs
```

---

## UI 레이어

### Page vs View vs Widget

| 구분 | 역할 | 예시 |
|------|------|------|
| Page | 전체 화면, 라우팅 대상 | `MyFolderPage` |
| View | 화면의 주요 영역 | `FolderListView` |
| Widget | 재사용 가능한 컴포넌트 | `FolderCard`, `LoadingWidget` |

### 예시 구조

```
ui/
├── page/
│   └── my_folder/
│       ├── my_folder_page.dart
│       └── share_folder_setting_page.dart
├── view/
│   └── folder_list_view.dart
└── widget/
    ├── loading.dart
    └── dialog/
        └── center_dialog.dart
```

---

## 네이밍 규칙

### 파일명

| 타입 | 규칙 | 예시 |
|------|------|------|
| Cubit | `*_cubit.dart` | `get_my_folders_cubit.dart` |
| State | `*_state.dart` | `folders_state.dart` |
| Repository | `*_repository.dart` | `local_folder_repository.dart` |
| Model | 단수형 | `folder.dart` |
| Page | `*_page.dart` | `my_folder_page.dart` |
| Widget | 설명적 | `loading.dart`, `center_dialog.dart` |

### 클래스명

| 타입 | 규칙 | 예시 |
|------|------|------|
| Cubit | `*Cubit` | `GetFoldersCubit` |
| State | `*State` | `FolderLoadedState` |
| Repository | `*Repository` | `LocalFolderRepository` |
| Model | PascalCase | `Folder` |
| Widget | PascalCase | `LoadingWidget` |

### 변수/메서드

- camelCase 사용
- 동사로 시작 (메서드): `getFolders()`, `deleteLink()`
- 명사 (변수): `folders`, `currentUser`

---

## 관련 문서

- [개발 환경 설정](DEVELOPMENT_SETUP.md)
- [테스트 가이드](TESTING_GUIDE.md)
- [기여 가이드](../CONTRIBUTING.md)
