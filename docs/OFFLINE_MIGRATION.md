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

## 새로운 DB 스키마

### folder 테이블 (수정)

```sql
CREATE TABLE folder (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(200) NOT NULL,
  visible INTEGER NOT NULL DEFAULT 1,
  thumbnail VARCHAR(10),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
```

### link 테이블 (신규)

```sql
CREATE TABLE link (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  folder_id INTEGER NOT NULL,
  url TEXT NOT NULL,
  title VARCHAR(500),
  image TEXT,
  describe TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  FOREIGN KEY (folder_id) REFERENCES folder(id) ON DELETE CASCADE
);

CREATE INDEX idx_link_folder_id ON link(folder_id);
CREATE INDEX idx_link_created_at ON link(created_at DESC);
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
│   ├── api/                    # 기존 API (Save Offline만 유지)
│   │   └── save_offline/
│   │
│   └── local/                  # 신규: 로컬 저장소
│       ├── database_helper.dart    # DB 초기화, 마이그레이션
│       ├── local_folder_repository.dart
│       └── local_link_repository.dart
│
├── models/
│   ├── folder/
│   │   └── folder.dart         # 기존 유지
│   └── link/
│       └── link.dart           # 기존 유지
```

---

## 구현 단계

### Phase 1: 로컬 DB 인프라 구축

1. [ ] `database_helper.dart` 생성 - DB 초기화, 버전 관리
2. [ ] 새로운 스키마로 테이블 생성
3. [ ] `LocalFolderRepository` 구현
4. [ ] `LocalLinkRepository` 구현

### Phase 2: Cubit 수정

1. [ ] `GetFoldersCubit` - API → LocalFolderRepository
2. [ ] 링크 관련 Cubit들 - API → LocalLinkRepository
3. [ ] 검색 기능 로컬 구현

### Phase 3: UI 연동

1. [ ] 폴더 목록 화면
2. [ ] 링크 목록 화면
3. [ ] 링크 추가/수정 화면
4. [ ] 검색 화면

### Phase 4: 기존 API 정리

1. [ ] 사용하지 않는 API 클라이언트 제거
2. [ ] DI 설정 정리
3. [ ] 테스트 코드 업데이트

### Phase 5: 공유 패널 연동

1. [ ] 네이티브 공유 패널에서 저장 시 로컬 DB 직접 저장
2. [ ] `ShareDataProvider` 수정

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

- [ ] DB 스키마 확정
- [ ] Repository 인터페이스 설계
- [ ] 단위 테스트 작성
- [ ] Cubit 수정
- [ ] UI 테스트
- [ ] 마이그레이션 로직 구현
- [ ] 기존 API 제거
- [ ] 문서 업데이트
