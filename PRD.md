# 제품 요구사항 정의서 (PRD)

- **작성일:** 2025년 12월 11일
- **최종 수정일:** 2026년 4월 21일
- **문서 버전:** v3.2 (App Store Submission Build)

---

## 제품명: MuscleLog (머슬로그)

**태그라인:** 점진적 과부하 운동 기록 & 코칭 앱

---

## 1. Overview (개요)

### Problem Statement (문제 정의)

- **문제 정의:** 많은 운동인들이 '어느 정도의 강도'로 운동해야 성장이 지속되는지 파악하지 못해 정체기(Plateau)를 겪음. 단순 기록 앱은 '다음 목표'를 제시해주지 않음.
- **왜 중요한가:** 근성장의 핵심 원리인 **점진적 과부하(Progressive Overload)**는 감이 아닌 체계적인 데이터 기반이어야 함.
- **타겟 고객:** 20~40대 피트니스 고관여층 (체계적인 몸 변화를 원하는 직장인/학생)

### 핵심 가치

1. **간편한 운동 기록:** 빠르고 직관적인 세트별 기록 시스템
2. **규칙 기반 코칭:** 수행 데이터(무게/횟수/강도)를 분석하여 다음 목표 제시
3. **시각적 성장 추적:** 차트와 달력으로 운동 히스토리 확인

---

## 2. 개발 현황 (Development Status)

### ✅ 완료된 기능 (v1.0 Core)

| 기능 | 설명 | 상태 |
|------|------|------|
| **인증 시스템** | 네이티브 Google Sign-In + Apple Sign-In (iOS/Android) | ✅ 완료 |
| **App Store 컴플라이언스** | App Store Guideline 4.8.0 준수 — Apple/Google 로그인 동시 제공 | ✅ 완료 |
| **프로필 관리** | 사용자 정보 (나이, 성별, 키, 몸무게, 운동 경력) | ✅ 완료 |
| **운동 기준 설정** | 운동별 기준 정보 등록 (운동명, 부위, 타입) | ✅ 완료 |
| **세트 기록** | 무게, 횟수, 강도(RPE) 입력 | ✅ 완료 |
| **운동 보관함** | 보관된 운동/루틴을 홈 화면 현재 날짜에 즉시 추가 | ✅ 완료 |
| **운동 분석** | 1RM 계산, 다음 세션 무게 추천 (규칙 기반) | ✅ 완료 |
| **달력 뷰** | 월별 운동 기록 확인 | ✅ 완료 |
| **차트 분석** | 운동별 성장 추이 시각화 (주간/월간) | ✅ 완료 |
| **인앱 구독** | RevenueCat 기반 프리미엄 구독 | ✅ 완료 |
| **에러 모니터링** | Sentry 기반 크래시 리포팅 | ✅ 완료 |
| **이중 분석** | Amplitude + Firebase Analytics (GA4) 듀얼 트래킹 | ✅ 완료 |
| **크로스 플랫폼** | iOS, Android 동시 지원 | ✅ 완료 |

### ⏸️ 보류된 기능 (AI Pivot)

| 기능 | 설명 | 상태 |
|------|------|------|
| **ML Kit 자세 분석** | 영상 기반 포즈 감지 | ⏸️ 보류 |
| **Gemini AI 추천** | LLM 기반 맞춤 루틴 생성 | ⏸️ 보류 |
| **영상 중간 점검** | 기준 영상 vs 현재 영상 비교 | ⏸️ 보류 |

> **Pivot 사유:** AI 기능 개발보다 핵심 운동 기록 기능의 안정성과 UX에 집중하기로 결정. AI 기능은 v2.0에서 재검토 예정.

### 🚀 현재 상태 (v1.0 App Store 제출 준비)

- iOS 네이티브 빌드 이슈 해결 (Xcode Entitlements 설정, Error 1000)
- Apple Sign-In 완전 구현으로 App Store 재심사 준비 완료
- `google_sign_in ^7.x` 마이그레이션 완료 (싱글턴 API 대응)

---

## 3. 기술 스택 (Tech Stack)

### Frontend
- **Framework:** Flutter 3.x
- **상태관리:** Riverpod
- **코드 생성:** Freezed, json_serializable

### Backend
- **BaaS:** Supabase (PostgreSQL, Auth, Storage)
- **인증:** Supabase Auth + Native Google Sign-In + Apple Sign-In

### 분석 및 모니터링
- **이벤트 분석:** Amplitude v4 + Firebase Analytics (GA4) — 동일 이벤트를 양쪽에 동시 전송
- **크래시 모니터링:** Sentry Flutter

### 주요 패키지
```yaml
dependencies:
  flutter_riverpod: ^2.4.9          # 상태 관리
  supabase_flutter: ^2.3.0          # 백엔드
  google_sign_in: ^7.2.0            # 네이티브 구글 로그인 (v7 싱글턴 API)
  sign_in_with_apple: ^6.1.1        # 네이티브 애플 로그인
  firebase_core: ^4.7.0             # Firebase 초기화
  firebase_analytics: ^12.3.0       # GA4 이벤트 분석
  amplitude_flutter: ^4.0.0         # Amplitude 이벤트 분석
  table_calendar: ^3.0.9            # 달력 UI
  fl_chart: ^0.66.0                 # 차트 시각화
  purchases_flutter: ^9.11.0        # RevenueCat 인앱 구독
  sentry_flutter: ^8.0.0            # 크래시 모니터링
  image_picker: ^1.0.7              # 미디어 선택
  video_player: ^2.8.2              # 영상 재생
```

---

## 4. 데이터 모델 (Database Schema)

### ERD 개요

```
users (Supabase Auth)
  │
  ├── profiles (1:1)
  │     - height, weight, birth_date, fitness_level, goal
  │
  └── exercise_baselines (1:N)
        │ - exercise_name, body_part, movement_type
        │
        └── workout_sets (1:N)
              - weight, reps, difficulty, workout_date
```

### 테이블 정의

```sql
-- 1. 사용자 프로필
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  height DECIMAL,
  weight DECIMAL,
  birth_date DATE,
  gender TEXT,              -- 'male', 'female', 'other'
  fitness_level TEXT,       -- 'beginner', 'intermediate', 'advanced'
  goal TEXT,                -- 'hypertrophy', 'strength'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 운동 기준 정보
CREATE TABLE public.exercise_baselines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  exercise_name TEXT NOT NULL,
  body_part TEXT,           -- 'upper', 'lower', 'core', 'full'
  movement_type TEXT,       -- 'push', 'pull', 'squat', 'hinge'
  equipment TEXT,           -- 'barbell', 'dumbbell', 'machine', 'bodyweight'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 운동 세트 기록
CREATE TABLE public.workout_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baseline_id UUID REFERENCES public.exercise_baselines(id),
  weight DECIMAL NOT NULL,
  reps INTEGER NOT NULL,
  difficulty TEXT,          -- 'easy', 'normal', 'hard'
  set_number INTEGER,
  workout_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 5. 핵심 알고리즘

### Progressive Overload (점진적 과부하)

```dart
/// 다음 운동 무게/횟수 추천
static (double weight, int reps) calculateNextWeight({
  required String difficulty,  // 'easy', 'normal', 'hard'
  required double currentWeight,
  required int currentReps,
}) {
  switch (difficulty) {
    case 'easy':
      // 쉬웠다면 → 무게 증가 (+2.5~5kg)
      return (currentWeight + 5.0, currentReps);
    case 'normal':
      // 적당했다면 → 소폭 증가 (+2.5kg)
      return (currentWeight + 2.5, currentReps);
    case 'hard':
      // 힘들었다면 → 유지
      return (currentWeight, currentReps);
  }
}
```

### 1RM 계산 (Epley Formula)

```dart
/// 1RM = 무게 × (1 + 횟수/30)
static double calculateOneRepMax(double weight, int reps) {
  return weight * (1 + (0.0333 * reps));
}
```

---

## 6. User Flow

### Phase 1: 온보딩 & 인증

1. 앱 실행 → 로그인 화면
2. **Google 로그인** 또는 **Apple 로그인** 선택
   - App Store Guideline 4.8.0 준수: 소셜 로그인 제공 시 반드시 Apple 로그인도 함께 제공해야 함
   - 두 옵션 모두 Supabase Auth를 통해 처리되며, 화면 전환은 `onAuthStateChange` 스트림이 담당
3. 프로필 설정 (키, 몸무게, 운동 목표)
4. 홈 화면 진입

### Phase 2: 운동 추가 (통합된 단일 플로우)

홈 화면에서 현재 선택된 날짜(selectedDate)를 기준으로 운동을 추가한다.
두 가지 진입 경로가 **동일한 클릭 깊이**로 통합되어 있다.

#### 경로 A: 직접 신규 운동 입력하기
1. 홈 화면 FAB(+) 탭 → 운동 추가 옵션 시트
2. "직접 신규 운동 입력하기" 선택
3. 운동명, 부위, 세트 정보 입력
4. 확인 → 현재 선택된 날짜에 즉시 추가

#### 경로 B: 내 보관함에서 불러오기
1. 홈 화면 FAB(+) 탭 → 운동 추가 옵션 시트
2. "내 보관함에서 불러오기" 선택
3. 보관함(운동 목록) 또는 루틴 탭에서 원하는 항목 체크
4. "N개 운동 추가하기" 버튼 탭 → **현재 선택된 날짜에 즉시 추가**
5. 홈 화면으로 자동 복귀 — 추가된 운동 즉시 확인 가능

> **설계 원칙:** 경로 B에서 과거에 존재하던 캘린더 날짜 선택 팝업은 완전히 제거되었다.
> 홈 화면에서 이미 날짜를 선택한 상태에서 운동을 추가하므로, 중복 날짜 선택 단계는 불필요한 마찰이다.
> 선택한 날짜가 오늘이면 즉시 DB에 저장되고, 미래 날짜이면 planned_workouts 테이블에 예약된다.

### Phase 3: 운동 기록

1. 홈 화면에 표시된 운동 카드 선택
2. 세트별 기록 입력:
   - 무게 (kg)
   - 횟수 (reps)
   - 강도 (쉬움/보통/어려움)
3. 저장 → 다음 세션 추천 확인

### Phase 4: 분석 확인

1. 홈 화면 → 운동 카드 또는 분석 탭 이동
2. 상세 분석 화면:
   - 1RM 추이 차트
   - 볼륨 추이 차트 (주간/월간 토글)
   - 월간 부위별 밸런스 레이더 차트
   - 다음 세션 추천
3. 달력에서 날짜별 기록 확인

---

## 7. 인증 아키텍처

### 지원 로그인 방식

| 방식 | 플랫폼 | 구현 | 비고 |
|------|--------|------|------|
| Google Sign-In | iOS, Android | `google_sign_in ^7.x` → `signInWithIdToken` | App Store 1차 심사 통과 |
| Apple Sign-In | iOS | `sign_in_with_apple` → `signInWithIdToken` | App Store Guideline 4.8.0 필수 요건 |

### 인증 초기화 순서 (main.dart)

```
Firebase.initializeApp()          ← Firebase Analytics 사용을 위해 최우선
  ↓
initializeDateFormatting('ko_KR')
  ↓
SupabaseService.initialize()
  ↓
RevenueCatService.init()
  ↓
AnalyticsService().init()         ← Amplitude + Firebase 듀얼 트래킹 초기화
  ↓
SentryFlutter.init() → runApp()
```

### Apple Sign-In 플로우

```
SignInWithApple.getAppleIDCredential()   ← sign_in_with_apple 패키지
        ↓
  identityToken (JWT) 추출
        ↓
Supabase.auth.signInWithIdToken(
  provider: OAuthProvider.apple,
  idToken: identityToken,
)
        ↓
  onAuthStateChange → MainScreen
```

---

## 8. 향후 로드맵

### v1.1 (단기)
- [ ] 운동 타이머 기능
- [ ] 휴식 시간 알림
- [ ] 데이터 내보내기 (CSV)
- [ ] Android 구독 시스템 (RevenueCat)

### v1.2 (중기)
- [ ] 소셜 기능 (운동 공유)
- [ ] 목표 설정 및 알림
- [ ] 위젯 지원 (iOS/Android)

### v2.0 (장기 - AI 재도입 검토)
- [ ] ML Kit 자세 분석 재검토
- [ ] LLM 기반 맞춤 코칭
- [ ] 영상 중간 점검 기능

---

## 9. 부록

### A. 경쟁사 분석

| 앱 | 강점 | 약점 | MuscleLog 차별점 |
|----|------|------|------------------|
| 플랜핏 | AI 루틴 추천 | 자세 피드백 없음 | 규칙 기반 명확한 증량 가이드 |
| 번핏 | 편리한 기록 | 수동적 (코칭 없음) | 능동적 다음 목표 제시 |
| 강스짐 | 커뮤니티 | 기록 기능 부족 | 데이터 기반 분석 |

### B. 성공 지표 (KPI)

| 지표 | 목표 |
|------|------|
| DAU | 1,000명 (런칭 3개월) |
| 7일 리텐션 | 40% 이상 |
| 평균 세션 기록 | 주 3회 이상 |
| 앱스토어 평점 | 4.5점 이상 |

---

*문서 끝*
