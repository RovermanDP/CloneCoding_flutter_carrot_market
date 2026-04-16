# 검색 기능 추가 계획

## Context

당근마켓 클론코딩 프로젝트에 검색 기능을 추가한다.  
백엔드는 이미 `/api/listings?region={region}&query={searchTerm}` 형태로 검색 쿼리 파라미터를 지원하고 있다.  
홈 화면 AppBar에 검색 아이콘 버튼도 존재하지만 `onPressed`가 비어있는 상태다.  
프론트엔드 Repository 메서드와 검색 UI 화면만 추가하면 된다.

---

## 파일 구조

### 수정할 파일
1. `lib/repository/contents_repository.dart` — 검색 메서드 추가
2. `lib/pages/home.dart` — 검색 아이콘 onPressed 연결

### 새로 만들 파일
1. `lib/pages/search.dart` — 검색 전용 화면

---

## 데이터 구조

**추가 타입 없음** — 기존 `typedef ContentItem = Map<String, dynamic>` 그대로 사용.  
검색 결과도 목록 조회 결과와 동일한 형태다 (API가 같은 `/api/listings` 엔드포인트를 사용).

---

## 구현 상세

### 1. `contents_repository.dart` — 검색 메서드 추가

```dart
Future<List<ContentItem>> searchContents(String query, String location) async {
  final Map<String, dynamic> json = await _getJson(
    '/api/listings',
    <String, String>{'region': location, 'query': query},
  );
  final List<dynamic> items = json['items'] as List<dynamic>? ?? <dynamic>[];
  return items
      .map((dynamic item) => _mapListing(
          Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
      .toList();
}
```

- `loadContentsFromLocation()`과 동일한 `_getJson` → `_mapListing` 패턴을 그대로 따름
- `location`(region)과 `query`를 모두 파라미터로 받아 현재 지역 내 검색
- 삽입 위치: `loadFavoriteContents()` 아래

### 2. `lib/pages/search.dart` — 검색 화면 (신규)

**패턴**: `home.dart`의 FutureBuilder + ListView 패턴을 따름

**상태 변수**:
```dart
String _submittedQuery = '';  // 실제로 검색된 쿼리 (onSubmitted 시 갱신)
final TextEditingController _controller = TextEditingController();
```

**구조**:
- `Scaffold`
  - `AppBar`: title 자리에 `TextField` (autofocus: true)
    - `onSubmitted`에서 `setState(() => _submittedQuery = value)`
  - `body`:
    - `_submittedQuery`가 비어있으면 → 빈 상태 안내 UI
    - `_submittedQuery`가 있으면 → `FutureBuilder` → `ListView.separated`

**네비게이션**: 아이템 탭 시 `Navigator.push` → `DetailContentView(data: data)` (home.dart와 동일)

**생성자**:
```dart
const SearchPage({super.key, required this.location});
final String location;  // 현재 선택된 지역 (home.dart에서 전달)
```

### 3. `home.dart` — 검색 버튼 연결

```dart
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => SearchPage(location: currentLocation),
    ),
  );
},
```

---

## FutureBuilder 재실행 방식

`setState(() => _submittedQuery = value)` 호출 시 rebuild → 새 Future 생성 → API 재호출.  
home.dart의 `FutureBuilder(future: _loadContents(), ...)` 패턴과 동일하다.

---

## 검증

1. 백엔드 서버 실행 (`cd backend && node src/server.mjs`)
2. Flutter 앱 실행 (`flutter run`)
3. 홈 화면 AppBar의 돋보기 아이콘 탭 → 검색 화면으로 이동 확인
4. 검색어 입력 후 엔터 → 해당 지역 내 검색 결과 표시 확인
5. 결과 없는 검색어 입력 → "No results found." 안내 확인
6. 검색 결과 아이템 탭 → 상세 화면 이동 확인
7. 지역 변경 후 동일 검색어 → 다른 결과 출력 확인 (지역 필터 확인)
