-- workout_sessions 테이블 생성
-- 운동 완료 시 강도(difficulty), 총 볼륨, 운동 시간을 저장하여 추후 분석 및 AI 루틴 추천에 활용

CREATE TABLE IF NOT EXISTS workout_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- [핵심] 어떤 운동에 대한 평가인가? (개별 운동 단위 평가)
  baseline_id UUID REFERENCES exercise_baselines(id) ON DELETE CASCADE,
  
  workout_date DATE DEFAULT CURRENT_DATE,
  difficulty VARCHAR(20) CHECK (difficulty IN ('easy', 'normal', 'hard')),
  total_volume NUMERIC,
  duration_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- RLS 정책 설정
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 세션만 조회 가능
CREATE POLICY "Users can view their own sessions"
  ON workout_sessions FOR SELECT
  USING (auth.uid() = user_id);

-- 사용자는 자신의 세션만 삽입 가능
CREATE POLICY "Users can insert their own sessions"
  ON workout_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 사용자는 자신의 세션만 수정 가능
CREATE POLICY "Users can update their own sessions"
  ON workout_sessions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 사용자는 자신의 세션만 삭제 가능
CREATE POLICY "Users can delete their own sessions"
  ON workout_sessions FOR DELETE
  USING (auth.uid() = user_id);

