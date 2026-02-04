# 오프라인 전환 작업 계획

## 개요

링크 조회/업로드를 백엔드 API 대신 앱 내 로컬 DB(SQLite)에 저장하는 방식으로 전환합니다.

### 목표

- 네트워크 의존성 제거
- 앱 응답 속도 향상
- 오프라인 환경에서도 완전한 기능 제공

### 유지되는 API

| API | 이유 |
|-----|------|
| `GET /save-offline` | 불러오기 이력 조회 |
| `POST /save-offline` | 불러오기 완료 처리 |

### 제거/대체되는 API

| API | 대체 방식 |
|-----|----------|
| Folders API | 로컬 SQLite |
| Links API | 로컬 SQLite |
| Share Folder API | 제거 (공유 기능 제거) |
| Users API | 로컬 저장 (필요한 부분만) |
| Picks API | 제거 |
| Reports API | 제거 |

---

## 현재 구조 분석

### 로컬 저장소 현황

| 파일 | 역할 | 기술 |
|------|------|------|
| `share_db.dart` | 폴더 정보 저장 | SQLite (sqflite) |
| `share_data_provider.dart` | 네이티브 공유 패널 연동 | MethodChannel |
| `shared_pref_provider.dart` | 간단한 설정 저장 | SharedPreferences |

### 현재 DB 스키마 (share_db.dart)

```sql
-- folder 테이블만 존재
CREATE TABLE folder (
  seq INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(200) NOT NULL UNIQUE,
  visible BOOLEAN NOT NULL DEFAULT 1,
  imageLink VARCHAR(2000),
  time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
```

### 필요한 변경사항

1. **link 테이블 추가** 필요
2. folder 테이블에 **id 컬럼 추가** (서버 ID 매핑용, 선택적)

---

## 데이터 구조 정의

### 현재 서버 모델 vs 로컬 DB 모델

#### Folder 모델 비교

| 필드 | 서버 모델 | 로컬 DB | 비고 |
|------|----------|---------|------|
| `id` | int? | INTEGER PK | 유지 |
| `name` | String? | TEXT NOT NULL | 유지 |
| `thumbnail` | String? | TEXT | 유지 (폴더 아이콘) |
| `visible` | bool? | INTEGER | **제거** (오프라인에서 의미 없음) |
| `links` | int? | - | 제거 (쿼리로 계산) |
| `time` | String? (created_date_time) | TEXT | 유지 |
| `isClassified` | bool? | INTEGER | 유지 (미분류 폴더 구분) |
| `isAdmin` | bool? | - | **제거** (공유 기능 제거) |
| `shared` | bool? | - | **제거** (공유 기능 제거) |
| `membersCount` | int? | - | **제거** (공유 기능 제거) |

#### Link 모델 비교

| 필드 | 서버 모델 | 로컬 DB | 비고 |
|------|----------|---------|------|
| `id` | int? | INTEGER PK | 유지 |
| `url` | String? | TEXT NOT NULL | 유지 |
| `title` | String? | TEXT | 유지 |
| `image` | String? | TEXT | 유지 (썸네일 URL) |
| `describe` | String? | TEXT | 유지 (메모) |
| `folderId` | int? | INTEGER FK | 유지 |
| `time` | String? (created_date_time) | TEXT | 유지 |
| `user` | DetailUser? | - | **제거** (오프라인에서 불필요) |
| `inflowType` | String? | TEXT | 유지 (유입 경로) |

---

## 새로운 DB 스키마

### folder 테이블

```sql
CREATE TABLE folder (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  thumbnail TEXT,
  is_classified INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 미분류 폴더는 name='unclassified', is_classified=0 으로 구분
```

| 컬럼 | 타입 | 설명 | 제약조건 |
|------|------|------|----------|
| id | INTEGER | 기본키 | PK, AUTOINCREMENT |
| name | TEXT | 폴더 이름 | NOT NULL |
| thumbnail | TEXT | 폴더 아이콘 코드 | nullable |
| is_classified | INTEGER | 분류 여부 (0=미분류) | NOT NULL, DEFAULT 1 |
| created_at | TEXT | 생성 시간 (ISO 8601) | NOT NULL |
| updated_at | TEXT | 수정 시간 (ISO 8601) | NOT NULL |

### link 테이블

```sql
CREATE TABLE link (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  folder_id INTEGER NOT NULL,
  url TEXT NOT NULL,
  title TEXT,
  image TEXT,
  describe TEXT,
  inflow_type TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (folder_id) REFERENCES folder(id) ON DELETE CASCADE
);

CREATE INDEX idx_link_folder_id ON link(folder_id);
CREATE INDEX idx_link_created_at ON link(created_at DESC);
CREATE INDEX idx_link_title ON link(title);  -- 검색용
```

| 컬럼 | 타입 | 설명 | 제약조건 |
|------|------|------|----------|
| id | INTEGER | 기본키 | PK, AUTOINCREMENT |
| folder_id | INTEGER | 폴더 FK | NOT NULL, FK |
| url | TEXT | 링크 URL | NOT NULL |
| title | TEXT | 링크 제목 | nullable |
| image | TEXT | 썸네일 이미지 URL | nullable |
| describe | TEXT | 메모/설명 | nullable |
| inflow_type | TEXT | 유입 경로 (SHARE, MANUAL 등) | nullable |
| created_at | TEXT | 생성 시간 (ISO 8601) | NOT NULL |
| updated_at | TEXT | 수정 시간 (ISO 8601) | NOT NULL |

---

## Dart 모델 클래스 (로컬용)

### LocalFolder

```dart
class LocalFolder {
  final int? id;
  final String name;
  final String? thumbnail;
  final bool isClassified;
  final String createdAt;
  final String updatedAt;

  // 링크 개수는 쿼리로 계산
  int? linksCount;

  const LocalFolder({
    this.id,
    required this.name,
    this.thumbnail,
    this.isClassified = true,
    required this.createdAt,
    required this.updatedAt,
    this.linksCount,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'thumbnail': thumbnail,
    'is_classified': isClassified ? 1 : 0,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory LocalFolder.fromMap(Map<String, dynamic> map) => LocalFolder(
    id: map['id'] as int?,
    name: map['name'] as String,
    thumbnail: map['thumbnail'] as String?,
    isClassified: (map['is_classified'] as int) == 1,
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String,
    linksCount: map['links_count'] as int?,
  );
}
```

### LocalLink

```dart
class LocalLink {
  final int? id;
  final int folderId;
  final String url;
  final String? title;
  final String? image;
  final String? describe;
  final String? inflowType;
  final String createdAt;
  final String updatedAt;

  const LocalLink({
    this.id,
    required this.folderId,
    required this.url,
    this.title,
    this.image,
    this.describe,
    this.inflowType,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'folder_id': folderId,
    'url': url,
    'title': title,
    'image': image,
    'describe': describe,
    'inflow_type': inflowType,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory LocalLink.fromMap(Map<String, dynamic> map) => LocalLink(
    id: map['id'] as int?,
    folderId: map['folder_id'] as int,
    url: map['url'] as String,
    title: map['title'] as String?,
    image: map['image'] as String?,
    describe: map['describe'] as String?,
    inflowType: map['inflow_type'] as String?,
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String,
  );
}
```

---

## 서버 → 로컬 변환

### Folder 변환

```dart
LocalFolder fromServerFolder(Folder serverFolder) {
  return LocalFolder(
    id: serverFolder.id,
    name: serverFolder.name ?? '',
    thumbnail: serverFolder.thumbnail,
    isClassified: serverFolder.isClassified ?? true,
    createdAt: serverFolder.time ?? DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
  );
}
```

### Link 변환

```dart
LocalLink fromServerLink(Link serverLink) {
  return LocalLink(
    id: serverLink.id,
    folderId: serverLink.folderId ?? 0,
    url: serverLink.url ?? '',
    title: serverLink.title,
    image: serverLink.image,
    describe: serverLink.describe,
    inflowType: serverLink.inflowType,
    createdAt: serverLink.time ?? DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
  );
}
```

---

## 네이티브 공유 패널 연동 변경

### 현재 구조 (서버 연동)

네이티브(iOS/Android)에서 공유 패널 UI를 통해 링크와 폴더를 저장하고, Flutter에서 일괄 업로드하는 구조입니다.

```
┌─────────────────────────────────────────────────────────────────┐
│  네이티브 공유 패널 (iOS/Android)                                │
│  - 사용자가 다른 앱에서 "공유" → 링크풀 선택                       │
│  - 네이티브 UI에서 폴더 선택/생성, 메모 입력                       │
│  - 네이티브 로컬 저장소에 임시 저장                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Flutter 앱 실행 시                                             │
│  - ShareDataProvider.getNewLinks()                              │
│  - ShareDataProvider.getNewFolders()                            │
│  - MethodChannel('share_data_provider')로 네이티브 데이터 조회    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  FolderApi.bulkSave()                                           │
│  - POST /bulk API 호출                                          │
│  - 서버에 폴더/링크 일괄 업로드                                   │
│  - 성공 시 ShareDataProvider.clearLinksAndFolders() 호출         │
└─────────────────────────────────────────────────────────────────┘
```

### 변경 후 구조 (로컬 DB)

```
┌─────────────────────────────────────────────────────────────────┐
│  네이티브 공유 패널 (iOS/Android)                                │
│  - 동일하게 네이티브 UI에서 링크/폴더 입력                        │
│  - 네이티브 로컬 저장소에 임시 저장 (기존과 동일)                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Flutter 앱 실행 시                                             │
│  - ShareDataProvider.getNewLinks()                              │
│  - ShareDataProvider.getNewFolders()                            │
│  - (기존과 동일하게 네이티브에서 데이터 조회)                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  LocalRepository.bulkInsert() (신규)                            │
│  - 로컬 SQLite DB에 직접 저장                                    │
│  - 서버 API 호출 없음                                            │
│  - 성공 시 ShareDataProvider.clearLinksAndFolders() 호출         │
└─────────────────────────────────────────────────────────────────┘
```

### 변경 대상 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/provider/api/folders/folder_api.dart` | `bulkSave()` 제거 |
| `lib/provider/share_data_provider.dart` | `loadServerData()` 제거/수정 |
| `lib/provider/local/local_bulk_repository.dart` | **신규** - 로컬 일괄 저장 |

### 신규 메서드: LocalBulkRepository

```dart
class LocalBulkRepository {
  final Database _db;

  /// 네이티브 공유 패널에서 받은 데이터를 로컬 DB에 일괄 저장
  Future<bool> bulkInsert() async {
    try {
      // 1. 네이티브에서 새 폴더/링크 가져오기
      final newFolders = await ShareDataProvider.getNewFolders();
      final newLinks = await ShareDataProvider.getNewLinks();

      if (newFolders.isEmpty && newLinks.isEmpty) {
        return true;
      }

      // 2. 트랜잭션으로 일괄 저장
      await _db.transaction((txn) async {
        // 폴더 저장
        for (final folderData in newFolders) {
          await txn.insert('folder', {
            'name': folderData['name'],
            'is_classified': 1,
            'created_at': folderData['created_at'],
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        // 링크 저장
        for (final linkData in newLinks) {
          // 폴더 이름으로 folder_id 조회
          final folderId = await _getFolderIdByName(txn, linkData['folder_name']);

          await txn.insert('link', {
            'folder_id': folderId,
            'url': linkData['url'],
            'title': linkData['title'],
            'image': linkData['image'],
            'describe': linkData['describe'],
            'inflow_type': 'SHARE',
            'created_at': linkData['created_at'],
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      });

      // 3. 네이티브 임시 저장소 비우기
      await ShareDataProvider.clearLinksAndFolders();

      return true;
    } catch (e) {
      Log.e('bulkInsert error: $e');
      return false;
    }
  }
}
```

---

## 전환 대상 API → 로컬 DB 매핑

### Folders API

| 기존 API | 로컬 DB 메서드 |
|---------|---------------|
| `GET /folders` | `LocalFolderRepository.getAll()` |
| `POST /folders` | `LocalFolderRepository.insert()` |
| `PATCH /folders/{id}` | `LocalFolderRepository.update()` |
| `DELETE /folders/{id}` | `LocalFolderRepository.delete()` |

### Links API

| 기존 API | 로컬 DB 메서드 |
|---------|---------------|
| `GET /folders/{id}/links` | `LocalLinkRepository.getByFolderId()` |
| `GET /links/unclassified` | `LocalLinkRepository.getUnclassified()` |
| `GET /links/{id}` | `LocalLinkRepository.getById()` |
| `POST /links` | `LocalLinkRepository.insert()` |
| `PATCH /links/{id}` | `LocalLinkRepository.update()` |
| `DELETE /links/{id}` | `LocalLinkRepository.delete()` |
| `GET /links/search` | `LocalLinkRepository.search()` |

---

## 파일 구조 계획

```
lib/
├── provider/
│   ├── api/                         # 기존 API (Save Offline만 유지)
│   │   └── save_offline/
│   │       └── save_offline_api.dart
│   │
│   ├── local/                       # 신규: 로컬 저장소
│   │   ├── database_helper.dart         # DB 초기화, 마이그레이션
│   │   ├── local_folder_repository.dart # 폴더 CRUD
│   │   ├── local_link_repository.dart   # 링크 CRUD
│   │   └── local_bulk_repository.dart   # 네이티브 공유 패널 일괄 저장
│   │
│   ├── share_data_provider.dart     # 수정: loadServerData() 제거
│   └── share_db.dart                # 제거 또는 local/로 통합
│
├── models/
│   ├── local/                       # 신규: 로컬 전용 모델
│   │   ├── local_folder.dart
│   │   └── local_link.dart
│   ├── folder/
│   │   └── folder.dart              # 마이그레이션용 유지
│   └── link/
│       └── link.dart                # 마이그레이션용 유지
```

---

## 구현 단계

### Phase 1: 로컬 DB 인프라 구축 ✅ 완료

1. [x] `database_helper.dart` 생성 - DB 초기화, 버전 관리
2. [x] 새로운 스키마로 테이블 생성
3. [x] `LocalFolderRepository` 구현
4. [x] `LocalLinkRepository` 구현
5. [x] `LocalBulkRepository` 구현 (네이티브 공유 패널 + 서버 마이그레이션)
6. [x] `OfflineMigrationService` 구현 (서버 → 로컬 데이터 이전)
7. [x] 테스트 코드 작성 (33개 테스트 통과)

### Phase 2: Cubit 수정 ✅ 완료

1. [x] `LocalFoldersCubit` - GetFoldersCubit 로컬 버전
2. [x] `LocalLinksCubit` - GetLinksCubit 로컬 버전
3. [x] `LocalUploadLinkCubit` - UploadLinkCubit 로컬 버전
4. [x] `LocalLinksFromFolderCubit` - LinksFromSelectedFolderCubit 로컬 버전
5. [x] `LocalSearchLinksCubit` - SearchLinksCubit 로컬 버전
6. [x] `LocalDetailEditCubit` - DetailEditCubit 로컬 버전
7. [x] 모델 변환 확장 메서드 (`local_model_extensions.dart`)

### Phase 3: UI 연동 및 마이그레이션 🔄 부분 완료

1. [ ] 폴더 목록 화면 - 기존 Cubit → Local Cubit 교체
2. [ ] 링크 목록 화면 - 기존 Cubit → Local Cubit 교체
3. [ ] 링크 추가/수정 화면 - 기존 Cubit → Local Cubit 교체
4. [ ] 검색 화면 - 기존 Cubit → Local Cubit 교체
5. [x] 앱 시작 시 마이그레이션 로직 추가 (`AutoLoginCubit._runMigrationIfNeeded()`)

### Phase 4: 기존 API 정리 🔄 진행 예정

1. [ ] 사용하지 않는 API 클라이언트 제거 (FolderApi, LinkApi 등)
2. [ ] DI 설정 정리 (API 제거, Local 전용으로 변경)
3. [ ] 테스트 코드 업데이트

### Phase 5: 네이티브 공유 패널 연동 변경 ✅ 완료

1. [x] `LocalBulkRepository.bulkInsertFromNative()` 구현
2. [x] `ShareDataProvider.bulkSaveToLocal()` 신규 구현
3. [x] `home_view.dart`에서 `bulkSaveToLocal()` 사용하도록 변경
4. [x] `ShareDataProvider.loadServerData()` deprecated 처리
5. [x] `ShareDataProvider.loadServerDataAtFirst()` deprecated 처리
6. [x] 로그인 관련 파일에서 `loadServerData` 호출 제거

---

## 제거 대상

### 삭제할 파일

```
lib/provider/api/folders/folder_api.dart
lib/provider/api/folders/link_api.dart
lib/provider/api/folders/share_folder_api.dart
lib/provider/api/user/user_api.dart
lib/provider/api/user/profile_api.dart
lib/provider/api/report/report_api.dart
lib/provider/api/linkpool_pick/linkpool_pick_api.dart
```

### 삭제할 기능

#### 1. 공유 폴더 기능 (전체)
- 폴더 공유/초대
- 초대 링크 생성/수락
- 공유 폴더 멤버 관리
- 관리자 위임/추방

#### 2. 소셜/커뮤니티 기능
- **피드** - 다른 사용자의 공개 링크 탐색
- **다른 사용자 폴더 조회** - `GET /users/{userId}/folders`
- **타인 링크 검색** - `my_links_only=false` 옵션

#### 3. 링크풀 Pick (추천)
- 서버에서 큐레이션하는 추천 콘텐츠

#### 4. 신고 기능
- 링크/사용자 신고

#### 5. 사용자 계정 관련
- 회원가입/로그인 (Firebase Auth만 유지, 서버 연동 제거)
- 프로필 관리 (닉네임, 프로필 이미지)
- 직군 선택
- 회원 탈퇴 (서버 연동 제거)

#### 6. 폴더 공개/비공개 설정
- `visible` 속성 - 다른 사람에게 보여주기 위한 것이므로 의미 없어짐

---

## 마이그레이션 전략

오프라인 전환 시 기존 사용자의 데이터 손실을 방지하기 위한 전략입니다.

### 핵심 원리

1. **최초 1회 서버 데이터 다운로드**: 앱 업데이트 후 첫 실행 시 서버에서 해당 유저의 모든 폴더/링크 조회
2. **로컬 DB 저장**: 조회한 데이터를 로컬 SQLite에 저장
3. **완료 상태 기록**: `POST /save-offline` API로 서버에 "불러오기 완료" 상태 전달
4. **이후 서버 조회 차단**: 다음 앱 실행부터 `GET /save-offline`으로 확인 후, 완료 상태면 서버 조회 없이 로컬 DB만 사용

### 데이터 다운로드 플로우

```
┌─────────────────────────────────────────────────────────────────┐
│                         앱 시작                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              GET /save-offline (불러오기 이력 조회)               │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│   data: false (미완료)   │     │   data: true (완료)     │
└─────────────────────────┘     └─────────────────────────┘
              │                               │
              ▼                               │
┌─────────────────────────┐                   │
│  서버에서 데이터 다운로드  │                   │
│  - GET /folders         │                   │
│  - GET /folders/{id}/   │                   │
│        links (전체)      │                   │
└─────────────────────────┘                   │
              │                               │
              ▼                               │
┌─────────────────────────┐                   │
│    로컬 DB에 저장        │                   │
│  - folder 테이블        │                   │
│  - link 테이블          │                   │
└─────────────────────────┘                   │
              │                               │
              ▼                               │
┌─────────────────────────┐                   │
│  POST /save-offline     │                   │
│  (완료 상태 서버에 전달)  │                   │
└─────────────────────────┘                   │
              │                               │
              └───────────────┬───────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    로컬 DB 사용 (오프라인 모드)                   │
│           이후 모든 폴더/링크 CRUD는 로컬 DB에서 처리              │
└─────────────────────────────────────────────────────────────────┘
```

### 마이그레이션 시 호출할 API (1회성)

| 순서 | API | 용도 |
|------|-----|------|
| 1 | `GET /save-offline` | 이미 불러왔는지 확인 |
| 2 | `GET /folders` | 모든 폴더 조회 |
| 3 | `GET /folders/{id}/links` (반복) | 각 폴더의 모든 링크 조회 |
| 4 | `POST /save-offline` | 불러오기 완료 처리 |

### 마이그레이션 이후

- 서버 API 호출 **완전 차단** (Save Offline API 제외)
- 모든 CRUD 작업은 로컬 DB에서 처리
- 네트워크 연결 불필요

---

## 리스크 및 고려사항

### 데이터 손실

- 앱 삭제 시 모든 데이터 손실
- 기기 변경 시 데이터 이전 불가
- **대응**: 사용자 안내 필요

### 저장 공간

- 링크 이미지 URL만 저장 (이미지 자체는 캐시)
- 대량 링크 저장 시 DB 크기 증가
- **대응**: 주기적인 정리 기능 또는 제한

### 검색 성능

- SQLite FTS (Full-Text Search) 필요할 수 있음
- 초기에는 LIKE 검색으로 구현, 성능 이슈 시 FTS 도입

---

## 체크리스트

- [x] DB 스키마 확정
- [x] Repository 인터페이스 설계
- [x] 단위 테스트 작성 (33개)
- [x] Cubit 수정 (Local 버전 생성)
- [ ] UI 연동 (Local Cubit 교체)
- [x] 마이그레이션 로직 구현 (OfflineMigrationService)
- [ ] 기존 API 제거
- [x] 문서 업데이트

---

## 구현된 파일 목록

### 모델
- `lib/models/local/local_folder.dart` - 로컬 폴더 모델
- `lib/models/local/local_link.dart` - 로컬 링크 모델
- `lib/models/local/local_model_extensions.dart` - 모델 변환 확장

### Repository
- `lib/provider/local/database_helper.dart` - DB 초기화
- `lib/provider/local/local_folder_repository.dart` - 폴더 CRUD
- `lib/provider/local/local_link_repository.dart` - 링크 CRUD
- `lib/provider/local/local_bulk_repository.dart` - 일괄 저장
- `lib/provider/local/offline_migration_service.dart` - 마이그레이션

### Cubit
- `lib/cubits/folders/local_folders_cubit.dart` - 로컬 폴더 Cubit
- `lib/cubits/links/local_links_cubit.dart` - 로컬 링크 Cubit
- `lib/cubits/links/local_upload_link_cubit.dart` - 로컬 업로드 Cubit
- `lib/cubits/links/local_links_from_folder_cubit.dart` - 폴더별 링크 Cubit
- `lib/cubits/links/local_detail_edit_cubit.dart` - 링크 편집 Cubit
- `lib/cubits/home/local_search_links_cubit.dart` - 검색 Cubit

### 테스트
- `test/provider/local/local_folder_repository_test.dart`
- `test/provider/local/local_link_repository_test.dart`
- `test/provider/local/local_bulk_repository_test.dart`
