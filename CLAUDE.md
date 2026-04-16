# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# [IMPORTANT] 코드 작성 규칙

## 1. 기존 코드 패턴 준수 (Adhere to Existing Code Patterns)

새 코드를 작성하기 전에 반드시 기존 프로젝트의 구조와 패턴을 먼저 파악한다.

- 기존 CRUD 패턴, 폴더 구조, 아키텍처 설계를 분석한 뒤 코드를 생성한다
- 기존 코드베이스에 존재하는 네이밍 컨벤션, 파일 구성 방식, 레이어 분리 방식을 그대로 따른다
- 동작은 하지만 기존 구조와 맞지 않는 코드("pretty garbage")는 작성하지 않는다
- 새 기능을 추가할 때는 유사한 기존 기능의 구현 방식을 참고하여 일관성을 유지한다

## 2. 단일 진실 공급원 (One Source of Truth, OSoT)

중요한 정보나 로직은 반드시 한 곳에만 정의한다.

- 타입 정의, 상수, 설정값, 비즈니스 로직을 여러 곳에 중복 작성하지 않는다
- 동일한 로직이 이미 존재한다면 새로 작성하지 않고 해당 위치를 참조한다
- 중복 정의가 발생하면 나중에 변경 시 불일치 문제와 대규모 리팩토링이 발생하므로 초기에 방지한다
- 코드 생성 전, 동일하거나 유사한 정의가 프로젝트 내에 이미 존재하는지 먼저 확인한다

## 3. 견고한 에러 처리 (Robust Error Handling)

정상 흐름(happy path)뿐만 아니라 예외 상황과 엣지 케이스를 항상 처리한다.

- `console.log`로 에러를 처리하지 않는다. 적절한 예외 처리(try/catch, 에러 바운더리 등)를 사용한다
- 사용자의 예상치 못한 행동(빠른 연속 클릭, 잘못된 입력, 네트워크 실패 등)을 고려한다
- TypeScript에서 타입 안전성을 우회하기 위해 `any`를 사용하지 않는다
- 임시방편(temporary fix)으로 에러를 숨기는 코드는 작성하지 않는다
- 에러 발생 시 사용자에게 의미 있는 피드백을 제공하는 처리를 포함한다

## 4. 단일 책임 원칙 (Single Responsibility Principle, SRP)

모든 함수, 클래스, 모듈은 하나의 역할만 수행한다.

- UI 로직, 비즈니스 로직, 데이터 처리 로직을 하나의 함수나 파일에 혼합하지 않는다
- 함수가 길어지거나 여러 역할을 수행한다면 더 작은 단위로 분리한다
- 함수 이름만 보고 무슨 역할인지 명확히 알 수 있어야 한다
- 거대한 단일 파일(monolithic file)이 생기지 않도록 책임 단위로 파일을 분리한다

## 5. 공유 파일/폴더의 적극적 활용 (Effective Shared File/Folder Management)

재사용 가능한 로직은 반드시 공유 유틸리티로 분리하여 관리한다.

- 코드 생성 후, 재사용 가능한 함수나 컴포넌트가 있다면 `utils/`, `lib/`, `shared/` 등 공유 디렉터리로 이동한다
- 이미 공유 폴더에 존재하는 유틸리티가 있다면 새로 작성하지 않고 가져다 쓴다
- 새로운 공유 함수를 추가했다면 팀원이 인지할 수 있도록 커뮤니케이션한다
- 프로젝트 전반에 중복 코드가 흩어지는 것을 방지하여 유지보수성과 확장성을 높인다

---

## 프로젝트 목적

당근마켓 앱의 핵심 기능(상품 목록 조회, 상세 보기, 즐겨찾기)을 Flutter로 클론코딩하는 학습 프로젝트. Flutter 기본 패턴 습득이 목표다.

## 제약 조건

- **상태관리 라이브러리 추가 금지** — Provider, Riverpod, Bloc 없이 `StatefulWidget + setState`만 사용하는 것이 이 프로젝트의 의도적 선택이다. 기능을 추가할 때도 이 패턴을 유지한다.
- **모델 클래스 없음** — `ContentItem = Map<String, dynamic>` typedef를 사용하는 것이 이 프로젝트의 구조다. 별도 data class를 만들지 않는다.
- **이미지는 로컬 asset만 사용** — 백엔드 API가 반환하는 `imageUrl`은 `assets/images/ara-1.jpg`처럼 앱 번들 내 asset 경로다. 네트워크 이미지가 아니므로, 새 상품을 추가할 때 이미지 파일을 `assets/images/`에 직접 넣어야 한다.

## 빌드 & 실행

### 백엔드 서버 먼저 실행 (Flutter 앱보다 먼저)
```bash
cd backend
node src/server.mjs        # PORT 기본값: 4000
PORT=5000 node src/server.mjs  # 포트 변경 시
```

### Flutter 앱 실행
```bash
# iOS 시뮬레이터 / 웹 (기본값 localhost:4000 그대로 동작)
flutter run

# Android 에뮬레이터 (localhost가 아닌 10.0.2.2 필수)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000

# 다른 사용자 ID로 실행
flutter run --dart-define=DEMO_USER_ID=my-user
```

## 아키텍처 결정

**즐겨찾기 상태의 두 가지 소스**
즐겨찾기는 백엔드 DB(`/api/favorites`)가 진실의 소스(source of truth)다. `LocalStorageRepository`(`flutter_secure_storage`)는 현재 별개 용도로 존재하며, 즐겨찾기와 혼동하지 않도록 주의한다.

**Detail 페이지의 2단계 로딩**
`DetailContentView`는 Home에서 전달받은 `ContentItem`(목록 데이터)으로 즉시 렌더링한 뒤, `initState`에서 `/api/listings/:id`를 다시 호출해 `description`, `relatedListings` 등 상세 데이터를 덮어쓴다. 즉, 상세 페이지 진입 시 API 호출이 2번 발생하는 것이 의도된 구조다.

## 개발 환경 특이사항

| 환경 | API_BASE_URL |
|------|-------------|
| iOS 시뮬레이터 / 웹 | `http://localhost:4000` (기본값) |
| Android 에뮬레이터 | `http://10.0.2.2:4000` (필수 변경) |
| 실기기 | 개발 PC의 실제 IP (예: `http://192.168.1.x:4000`) |

백엔드 `better-sqlite3`는 동기 API다. 서버 코드에서 `await` 없이 DB 쿼리가 즉시 반환된다.

## Gotcha

**FutureBuilder가 setState마다 API를 재호출한다**
`home.dart`의 `FutureBuilder(future: _loadContents(), ...)`는 `future` 파라미터에 메서드를 직접 전달하기 때문에, `setState`가 호출될 때마다 새 Future가 생성되어 API를 다시 호출한다. 지역 전환 시 의도적으로 활용된 패턴이지만, 불필요한 `setState` 추가 시 의도치 않은 재호출이 발생한다.

**`ContentItem`의 키 이름이 API 응답과 다르다**
`ContentsRepository._mapListing()`에서 API 응답 필드명을 Flutter 내부 키로 변환한다. 예: `id` → `cid`, `imageUrl` → `image`, `mannerTemp` → `sellerTemp`. API 응답 필드명을 `ContentItem` 접근 시 직접 쓰면 항상 null이 나온다.
