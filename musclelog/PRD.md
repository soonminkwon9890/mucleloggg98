제품 요구사항 정의서 (PRD)작성일: 2025년 12월 11일최종 수정일: 2025년 12월 11일 (피벗 전략 반영)작성자: Product Manager문서 버전: v2.0 (Intensity & Coaching Pivot)[제품명: MuscleLog (머슬로그) - AI 강도 분석 및 점진적 과부하 코칭]1. Overview (개요)Problem Statement (문제 정의)문제 정의: 많은 중급자 운동인들이 '어느 정도의 강도'로 운동해야 성장이 지속되는지 파악하지 못해 정체기(Plateau)를 겪음. 단순 기록 앱은 '다음 목표'를 제시해주지 않으며, 유튜브 강의는 '내 수행 능력'을 모름.왜 중요한가: 근성장의 핵심 원리인 **점진적 과부하(Progressive Overload)**는 감이 아닌 철저한 수학적 계산과 수행 데이터에 기반해야 함. 사용자는 단순한 '기록 저장소'가 아닌, **"그래서 오늘 몇 kg로 해야 해?"**를 알려주는 파트너를 원함.타겟 고객: 20~40대 피트니스 고관여층 (3대 운동 중량 욕심이 있거나, 체계적인 몸 변화를 원하는 직장인/학생).핵심 가치:AI 강도 설계: 사용자의 수행 기록(RPE 포함)을 분석하여 최적의 증량 가이드 제공.하이브리드 코칭: 텍스트 기반의 빠른 기록과, 필요 시 영상 기반의 자세 점검(중간 점검)을 결합.Proposed Work (솔루션 & 기술 전략)솔루션 개요:사용자의 움직임 분석(Computer Vision) 기능은 유지하되, 이를 '자세 교정'이 아닌 '강도 설정 및 수행 능력 평가'의 보조 도구로 활용합니다.핵심 로직은 **RPE(운동 자각도)와 수행 데이터(무게/횟수)**를 결합하여 다음 세트 및 다음 세션의 목표 중량을 계산하는 AI 알고리즘입니다.'영상 중간 점검' 기능을 통해 초기 설정한 자세와 현재 자세를 비교하여, 강도가 높아짐에 따라 자세가 무너지는지(보상 작용)를 감지합니다.핵심 기능:운동 강도 분석 및 로드맵 제시:사용자가 수행한를 입력하면 1RM을 추산.예: "20kg으로 20회(보통 강도) 성공 → 다음엔 40kg 10회 도전 가능" 알고리즘 적용.하이브리드 기록 시스템 (Accordion UI):최초 1회 영상 분석 후, 반복 수행 시 영상 없이 데이터(무게/횟수/강도)만 빠르게 입력.직관적인 아코디언 UI로 이전 기록 확인 및 빠른 복사.영상 중간 점검 (Form Check):사용자가 원할 때 초기 '기준 영상'과 동일한 각도로 촬영 유도.두 영상을 비교 분석하여 "초반보다 승모근 개입이 늘었습니다(자세 무너짐)" 등의 피드백 제공.AI 맞춤 강도 추천 버튼:정체기 감지 시, AI가 강제적으로 부하를 높이거나(Overload) 디로딩(Deload)을 제안.개입 부위 피드백 (Muscle vs Joint):영상 분석 결과, 근육 텐션이 주가 되는지 관절 부하(Lock-out 등)가 주가 되는지 분석하여 텍스트 프롬프트로 저장.User Flow (상세 사용자 흐름)Phase 1: 온보딩 (Calibration)[진입] → [프로필 설정]: 나이, 성별, 키, 몸무게 입력.[운동 경력 설정]: 초급/중급/고급 선택 (초기 알고리즘 가중치 설정용).Phase 2: 최초 운동 설정 및 분석[영상 업로드/촬영][운동 분류 선택]:Step 1: 상체 / 하체 / 전신Step 2: (상체 선택 시) 밀기(Push) / 당기기(Pull)[수행 데이터 입력]: 무게(kg), 횟수(Reps).[주관적 강도 선택]:낮음 (RPE 1-4): 웜업 수준.보통 (RPE 5-7): 자극 위주, 3회 이상 더 할 수 있음.어려움 (RPE 8-10): 실패지점 근접.[분석 결과 저장 & 피드백]:DB 저장: users_log 테이블에 영상 및 데이터 저장.피드백 출력: "주동근(가슴)보다 관절(어깨) 개입이 높습니다. 팔꿈치 각도를 확인하세요." (의료법 준수 문구 사용).Phase 3: 반복 수행 (Routine Loop - 하이브리드)[기존 영상 클릭] → [액션: '이 운동 다시하기'][데이터 입력 모드 (영상 X)]:상체/밀기 등의 메타데이터는 자동 로드됨.사용자는 무게, 횟수, 강도만 입력.[AI 추천 적용]: 입력 창 하단에 "AI 추천: 오늘은 25kg 12회를 시도해보세요!" 문구 노출.[저장]: 영상 하단에 아코디언(Accordion) 형식으로 날짜별 텍스트 기록이 쌓임.Phase 4: 성장 관리 및 중간 점검[영상 중간 점검 버튼]: 아코디언 리스트 최하단에 위치.[촬영 가이드]: 초반 업로드 영상의 뼈대(Skeleton)를 고스트로 띄워 동일한 각도 유도.[비교 분석]:초반 영상 vs 현재 영상 비교.결과: "중량은 늘었으나, 가동범위(ROM)가 10% 줄었습니다." 또는 "근육 사용도가 15% 상승했습니다."Phase 5: 정체기 탈출 (AI Intervention)[조건]: 사용자가 2주 이상 같은 무게/횟수/강도를 반복 기록 시.[AI 맞춤 강도 추천 버튼 활성화]:클릭 시 AI가 강도(어려움)를 강제 설정하고, 그에 맞는 무게/횟수(예: 무게 ↑ 횟수 ↓)를 역산하여 세팅해줌.2. Data & Algorithm (데이터 및 알고리즘 전략)Database Schema (Supabase) - 수정됨SQL-- 1. 운동 기준 정보 테이블 (영상 포함)
CREATE TABLE public.exercise_baselines (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
user_id UUID REFERENCES public.users(id),
video_path TEXT NOT NULL, -- 기준 영상
body_part TEXT, -- 'UPPER', 'LOWER', 'FULL'
movement_type TEXT, -- 'PUSH', 'PULL'
feedback_prompt TEXT, -- "어깨 관절 개입 과다" 등 분석 내용
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 운동 수행 로그 테이블 (텍스트 위주, 아코디언 데이터)
CREATE TABLE public.workout_sets (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
baseline_id UUID REFERENCES public.exercise_baselines(id), -- 어떤 운동의 로그인지 연결
weight DECIMAL NOT NULL,
reps INTEGER NOT NULL,
rpe_level TEXT, -- 'LOW', 'MEDIUM', 'HIGH'
is_ai_recommended BOOLEAN DEFAULT FALSE, -- AI 추천 값 수용 여부
performance_score DECIMAL, -- 1RM 추산치 등 계산 결과
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 중간 점검 비교 테이블
CREATE TABLE public.check_points (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
baseline_id UUID REFERENCES public.exercise_baselines(id),
check_video_path TEXT NOT NULL,
comparison_result JSONB, -- { "rom_change": -10, "muscle_activation_change": +15... }
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
Progressive Overload Algorithm (핵심 로직)1RM 추정 공식 (Epley Formula 변형):$$1RM = Weight \times (1 + \frac{Reps}{30}) \times RPE\_Factor$$RPE_Factor: 낮음(1.0), 보통(1.05), 어려움(1.1) 등 가중치 부여.성장 가이드 로직:Input: 20kg / 20회 / 보통(RPE 7)Estimated 1RM: 약 33kg.Target Goal (근비대): 1RM의 70~80% 구간.Output: "40kg(1RM 상회 도전)은 위험하므로, 30kg으로 10~12회를 '어려움' 강도로 수행해보세요."3. Competitiveness Analysis (시장성 및 경쟁 우위 분석)A. 기존 PRD (시각화 중심) vs 수정 PRD (강도/코칭 중심) 비교비교 항목기존 PRD (시각화 & 통계)수정 PRD (강도 분석 & 코칭)시장성 우위핵심 가치"내가 어떻게 움직였는지 본다" (자기만족, 기록)"어떻게 해야 몸이 좋아지는지 알려준다" (문제해결)수정안 승사용자 유지율(Retention)낮음. 몇 번 찍어보고 신기해하다가 귀찮아서 이탈함.높음. 매 운동마다 다음 무게를 알려주므로 계속 써야 할 이유가 됨.수정안 승진입 장벽매우 높음. 헬스장에서 매 세트 촬영은 눈치 보이고 번거로움.낮음. '다시하기'는 텍스트 입력만 하면 되므로 빠르고 간편함.수정안 승수익화 가능성낮음. 단순 도구는 유료 결제 유도가 어려움.높음. "PT 선생님"을 대체하는 기능이므로 구독 모델 적용 용이.수정안 승결론:대한민국 피트니스 시장은 '헬시 플레저'와 '오운완' 트렌드를 넘어, **"효율적인 운동"**과 **"확실한 결과"**를 원합니다. 기존 안은 '보여주기식'에 가깝지만, 수정 안은 사용자의 **실질적인 고민(중량 정체, 루틴 설정)**을 해결해주므로 시장성이 월등히 높습니다.B. 경쟁사 벤치마킹 및 차별화 전략현재 한국 시장의 주요 경쟁사는 **'플랜핏(Planfit)'**과 **'번핏(Bunfit/BurnFit)'**입니다.1. 플랜핏 (Planfit) - AI 추천의 강자기능: 사용자 데이터를 기반으로 루틴과 무게를 완전히 자동 추천.한계: "왜 이 무게를 해야 하는지"에 대한 설명이 부족하고, 자세 피드백 기능이 없음(텍스트 위주).MuscleLog의 차별점:영상 기반 근거 제시: 단순히 숫자만 던지는 게 아니라, **"영상 중간 점검"**을 통해 자세가 무너지지 않는 선에서의 증량을 제안.아코디언 UI: 플랜핏보다 더 직관적인 히스토리 확인.2. 번핏 (Bunfit) - 기록의 강자기능: 매우 편리하고 자유도 높은 운동 일지(Logger). 커뮤니티 기능 강함.한계: 수동적임. 사용자가 직접 무게를 정해야 하며, 앱이 능동적으로 "더 드세요"라고 강하게 코칭하지 않음.MuscleLog의 차별점:능동적 개입: **'AI 맞춤 강도 추천 버튼'**을 통해 정체기에 빠진 사용자에게 명확한 목표(퀘스트)를 부여.하이브리드: 번핏의 장점(빠른 텍스트 기록)과 영상 분석의 장점을 합침.C. 최종 전략 제언MVP 출시 전략: '영상 분석'의 정확도보다는 '강도 추천 알고리즘'의 정교함에 집중하십시오. 사용자는 내 1RM을 정확히 맞춰주고, 다음 세트 무게를 딱 맞게 추천해줄 때 "소름 돋는다"며 팬이 됩니다.UI/UX 핵심: '다시하기' 버튼 클릭 시 영상 촬영 화면이 아닌, 텍스트 입력(아코디언) 화면이 먼저 뜨게 하여 사용자의 귀찮음을 최소화해야 합니다. (영상 촬영은 선택적 옵션으로 배치).마케팅 포인트: "아직도 감으로 운동하세요? AI가 계산해주는 안전한 증량 길라잡이, 머슬로그."
