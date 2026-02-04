# Backend API 문서

링크풀 앱에서 사용하는 Backend API 명세입니다.

## 기본 정보

| 항목 | 값 |
|------|------|
| Base URL | `https://api.linkpool.co.kr` |
| 인증 | Firebase ID Token (`x-auth-token` 헤더) |
| Content-Type | `application/json` |

## 응답 형식

```json
{
  "status": 0,
  "message": null,
  "error": null,
  "data": { ... }
}
```

| status | 설명 |
|--------|------|
| 0 | 성공 |
| 2001 | 중복 (링크) |
| 3000 | 중복 (일반) |
| 4000 | 중복 (신고) |

---

## Folders API

폴더 관련 API

### 내 폴더 목록 조회

```
GET /folders
```

**Response**
```json
[
  {
    "id": 1,
    "name": "폴더명",
    "thumbnail": "01",
    "visible": true,
    "links": 5,
    "time": "2023-05-15T10:30:00.000000",
    "shared": false
  }
]
```

> `name`이 `unclassified`인 경우 "미분류" 폴더

### 다른 사용자 폴더 조회

```
GET /users/{userId}/folders
```

### 폴더 생성

```
POST /folders
```

**Request Body**
```json
{
  "name": "폴더명",
  "visible": true,
  "created_at": "2023-05-15T10:30:00.000000",
  "shared": false
}
```

### 폴더 수정

```
PATCH /folders/{folderId}
```

**Request Body**
```json
{
  "name": "새 폴더명",
  "visible": false
}
```

### 폴더 삭제

```
DELETE /folders/{folderId}
```

### 대량 저장 (Bulk)

```
POST /bulk
```

**Request Body**
```json
{
  "new_links": [...],
  "new_folders": [...]
}
```

---

## Links API

링크 관련 API

### 폴더별 링크 목록 조회

```
GET /folders/{folderId}/links?page_no={pageNo}&page_size=10
```

**Response**
```json
{
  "links": [...],
  "total_count": 100,
  "has_more": true
}
```

### 전체 링크 조회 (피드)

```
GET /job-groups/0/links?page_no={pageNo}&page_size=10
```

### 미분류 링크 조회

```
GET /links/unclassified?page_no={pageNo}&page_size=10
```

### 링크 상세 조회

```
GET /links/{linkId}
```

**Response**
```json
{
  "id": 1,
  "url": "https://example.com",
  "title": "제목",
  "image": "https://...",
  "describe": "설명",
  "time": "2023-05-15T10:30:00.000000",
  "folder_id": 1,
  "inflow_type": "SHARE"
}
```

### 링크 생성

```
POST /links
```

**Request Body**
```json
{
  "url": "https://example.com",
  "title": "제목",
  "image": "https://...",
  "describe": "설명",
  "created_at": "2023-05-15T10:30:00.000000",
  "folder_id": 1,
  "inflow_type": "SHARE"
}
```

**Error Codes**
- `3000`, `2001`: 중복된 링크

### 링크 수정

```
PATCH /links/{linkId}
```

**Request Body**
```json
{
  "title": "새 제목",
  "describe": "새 설명",
  "folder_id": 2
}
```

### 링크 삭제

```
DELETE /links/{linkId}
```

### 링크 검색

```
GET /links/search?my_links_only={true|false}&keyword={keyword}&page_no={pageNo}&page_size=10
```

| 파라미터 | 설명 |
|---------|------|
| my_links_only | `true`: 내 링크만, `false`: 전체 |
| keyword | 검색어 |

### 폴더 내 링크 검색

```
GET /links/search/folder/{folderId}?keyword={keyword}&page_no={pageNo}&page_size=10
```

---

## Share Folder API

공유 폴더 관련 API

### 초대 링크 생성

```
POST /folders/{folderId}/invite-link
```

**Response**
```json
{
  "invite_token": "abc123...",
  "expires_at": "2023-05-20T10:30:00.000000"
}
```

### 초대 링크 정보 조회

```
GET /folders/{folderId}/invite-link
```

### 초대 수락

```
POST /folders/{folderId}/invite-link/accept
```

**Request Body**
```json
{
  "invite_token": "abc123..."
}
```

### 폴더 멤버 목록 조회

```
GET /folders/{folderId}/members
```

**Response**
```json
[
  {
    "id": 1,
    "nickname": "사용자1",
    "profile_img": "01",
    "is_admin": true
  }
]
```

### 관리자 위임

```
POST /folders/{folderId}/admin/delegate
```

**Request Body**
```json
{
  "memberId": "123"
}
```

### 멤버 추방

```
POST /folders/{folderId}/{userId}/displace
```

---

## Users API

사용자 관련 API

### 사용자 생성 (회원가입)

```
POST /users
```

### 내 정보 조회

```
GET /users/me
```

**Response**
```json
{
  "id": 1,
  "nickname": "닉네임",
  "profile_img": "01",
  "job_group_id": 1
}
```

### 내 정보 수정

```
PATCH /users/me
```

**Request Body**
```json
{
  "nickname": "새닉네임",
  "job_group_id": "2",
  "profile_img": "02"
}
```

### 특정 사용자 조회

```
GET /users/{userId}
```

### 닉네임 중복 확인

```
HEAD /users?nickname={nickname}
```

| 응답 코드 | 설명 |
|----------|------|
| 404 | 사용 가능 |
| 200 | 중복됨 |

### 회원 탈퇴

```
DELETE /users
```

---

## Reports API

신고 관련 API

### 신고하기

```
POST /reports
```

**Request Body**
```json
{
  "targetType": "LINK",
  "targetId": 123,
  "reasonType": "SPAM",
  "otherReason": null
}
```

| targetType | 설명 |
|-----------|------|
| LINK | 링크 신고 |
| USER | 사용자 신고 |

**Error Codes**
- `4000`: 이미 신고한 대상

---

## Save Offline API

링크 한번에 불러오기 관련 API

### 불러오기 이력 조회

사용자가 이전에 "링크 한번에 불러오기"를 완료했는지 확인합니다.

```
GET /save-offline
```

**Response**
```json
{
  "status": 0,
  "message": "",
  "data": true
}
```

| data | 설명 |
|------|------|
| `true` | 이미 불러오기 완료 |
| `false` | 아직 불러오기 안함 |

### 불러오기 완료 처리

"링크 한번에 불러오기"를 완료 처리합니다.

```
POST /save-offline
```

**Response**
```json
{
  "status": 0,
  "message": "",
  "data": null
}
```

---

## Picks API (Linkpool Pick)

링크풀 추천 관련 API

### 추천 목록 조회

```
GET /picks
```

**Response**
```json
[
  {
    "id": 1,
    "title": "추천 제목",
    "links": [...]
  }
]
```

---

## API 클라이언트 파일 위치

| 파일 | 설명 |
|------|------|
| `lib/provider/api/custom_client.dart` | HTTP 클라이언트 (인증 처리) |
| `lib/provider/api/folders/folder_api.dart` | 폴더 API |
| `lib/provider/api/folders/link_api.dart` | 링크 API |
| `lib/provider/api/folders/share_folder_api.dart` | 공유 폴더 API |
| `lib/provider/api/user/user_api.dart` | 사용자 API |
| `lib/provider/api/user/profile_api.dart` | 프로필 API |
| `lib/provider/api/report/report_api.dart` | 신고 API |
| `lib/provider/api/linkpool_pick/linkpool_pick_api.dart` | 추천 API |
| `lib/provider/api/save_offline/save_offline_api.dart` | 링크 불러오기 API |
