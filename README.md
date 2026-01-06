# MuscleLog (머슬로그)

> AI 강도 분석 및 점진적 과부하 코칭 앱

**"아직도 감으로 운동하세요? AI가 계산해주는 안전한 증량 길라잡이, 머슬로그."**

MuscleLog은 운동 기록을 넘어서, **"그래서 오늘 몇 kg로 해야 해?"**를 알려주는 AI 코칭 앱입니다. RPE(운동 자각도)와 수행 데이터를 분석하여 최적의 증량 가이드를 제공합니다.

## 주요 기능

### 🎯 AI 강도 설계

- **1RM 추정**: Epley Formula 변형을 사용한 정확한 1RM 계산
- **점진적 과부하 추천**: 다음 세트의 최적 무게/횟수 자동 추천
- **정체기 감지**: 2주 이상 변화 없을 시 자동 개입 (디로딩/강도 돌파)

### 📱 하이브리드 기록 시스템

- **최초 설정**: 영상 촬영으로 기준 자세 설정
- **빠른 기록**: 반복 운동 시 텍스트 입력만으로 빠른 기록
- **아코디언 UI**: 날짜별로 그룹핑된 직관적인 기록 확인

### 🤖 AI 영상 분석

- **Google ML Kit**: 실시간 포즈 감지 및 생체역학 분석
- **고스트 모드**: 기준 자세를 오버레이하여 동일 각도 촬영 유도
- **대칭성 분석**: 좌우 불균형 감지 및 피드백

### 📊 성장 추적

- **날짜별 그룹핑**: 같은 날짜의 운동을 루틴으로 묶어 표시
- **1RM 추적**: 시간에 따른 1RM 변화 시각화
- **AI 추천 히스토리**: AI가 제안한 무게/횟수 추적

## 기술 스택

### 프론트엔드

- **Flutter** (Latest Stable)
- **Riverpod** - 상태 관리
- **Freezed** - 불변 데이터 모델

### 백엔드

- **Supabase** - 인증, 데이터베이스, 스토리지
- **PostgreSQL** - 관계형 데이터베이스

### AI & 분석

- **Google ML Kit Pose Detection** - 포즈 감지
- **순수 생체역학 분석** - 관절 각도 및 대칭성 분석

### 미디어 처리

- **video_compress** - 영상 압축
- **image_picker** - 카메라/갤러리 접근
- **video_player** - 영상 재생

## 프로젝트 구조

```
lib/
├── core/                    # 공통 유틸리티
│   ├── constants/          # 앱 상수
│   ├── theme/              # 테마 설정
│   └── utils/              # 유틸리티 함수
├── data/                   # 데이터 레이어
│   ├── models/             # 데이터 모델 (Freezed)
│   ├── repositories/        # 데이터 저장소
│   └── services/           # 서비스 (Supabase)
├── domain/                 # 비즈니스 로직
│   └── algorithms/         # 알고리즘 (1RM, Progressive Overload)
├── presentation/           # UI 레이어
│   ├── providers/          # Riverpod Providers
│   ├── screens/            # 화면
│   └── widgets/            # 재사용 가능한 위젯
└── video/                  # 영상 분석
    └── ml_kit/             # ML Kit 연동
```

## 시작하기

### 필수 요구사항

- Flutter SDK (>=3.2.0)
- Dart SDK (>=3.2.0)
- Android Studio / Xcode
- Supabase 계정

### 설치

1. **저장소 클론**

```bash
git clone https://github.com/your-username/musclelog.git
cd musclelog
```

2. **의존성 설치**

```bash
flutter pub get
```

3. **환경 변수 설정**
   프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. **Freezed 코드 생성**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. **Supabase 데이터베이스 설정**
   Supabase 대시보드에서 다음 SQL을 실행하세요:

```sql
-- 프로필 테이블
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  experience_level TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 운동 기준 정보 테이블
CREATE TABLE public.exercise_baselines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id),
  exercise_name TEXT NOT NULL,
  target_muscle TEXT,
  body_part TEXT,
  movement_type TEXT,
  video_url TEXT,
  thumbnail_url TEXT,
  skeleton_data JSONB,
  feedback_prompt TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 운동 세트 기록 테이블
CREATE TABLE public.workout_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baseline_id UUID REFERENCES public.exercise_baselines(id),
  weight DECIMAL NOT NULL,
  reps INTEGER NOT NULL,
  rpe INTEGER,
  rpe_level TEXT,
  estimated_1rm DECIMAL,
  is_ai_suggested BOOLEAN DEFAULT FALSE,
  performance_score DECIMAL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 중간 점검 테이블
CREATE TABLE public.check_points (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baseline_id UUID REFERENCES public.exercise_baselines(id),
  check_video_path TEXT NOT NULL,
  comparison_result JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

6. **앱 실행**

```bash
flutter run
```

## 핵심 알고리즘

### 1RM 추정 (Epley Formula 변형)

```
1RM = Weight × (1 + Reps/30) × RPE_Factor
```

- RPE Factor:
  - 낮음 (RPE 1-4): 1.0
  - 보통 (RPE 5-7): 1.05
  - 어려움 (RPE 8-10): 1.1

### 점진적 과부하 추천

- **목표 범위**: 1RM의 70-80% (근비대 최적 구간)
- **RPE 기반 조정**:
  - RPE < 7: 무게 증량
  - RPE 7-9: 점진적 증가 (무게 또는 횟수)
  - RPE > 9: 무게 유지 또는 감소

## 주요 화면

- **온보딩**: 프로필 설정 및 운동 경력 선택
- **운동 추가**: 영상 촬영/업로드 및 운동 정보 입력
- **홈**: 운동 목록 및 아코디언 형식 기록 확인
- **운동 기록**: 빠른 텍스트 입력 및 AI 추천
- **중간 점검**: 고스트 모드로 자세 비교 분석

## 개발 상태

현재 프로젝트는 MVP 개발 단계입니다.

### 완료된 기능 ✅

- 사용자 인증 및 프로필 설정
- 운동 추가 및 영상 분석
- 1RM 계산 알고리즘
- 점진적 과부하 추천 알고리즘
- 아코디언 형식 기록 UI
- 기본 생체역학 분석

### 개발 중 🚧

- 영상 중간 점검 (고스트 모드)
- 정체기 감지 및 개입
- 상세 통계 및 차트

## 기여하기

기여를 환영합니다! 이슈를 열거나 Pull Request를 보내주세요.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 문의

프로젝트에 대한 질문이나 제안사항이 있으시면 이슈를 열어주세요.

---

**Made with 💪 for fitness enthusiasts**
