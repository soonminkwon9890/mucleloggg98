-- planned_workouts 테이블 생성
-- 미래의 운동 계획을 저장하는 테이블
CREATE TABLE IF NOT EXISTS planned_workouts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  baseline_id UUID REFERENCES exercise_baselines(id) ON DELETE CASCADE NOT NULL,
  scheduled_date DATE NOT NULL,
  target_weight NUMERIC NOT NULL,
  target_reps INTEGER NOT NULL,
  target_sets INTEGER DEFAULT 3,
  ai_comment TEXT,
  is_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

ALTER TABLE planned_workouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own planned workouts"
  ON planned_workouts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own planned workouts"
  ON planned_workouts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own planned workouts"
  ON planned_workouts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own planned workouts"
  ON planned_workouts FOR DELETE
  USING (auth.uid() = user_id);

-- profiles 테이블에 workout_goal 컬럼 추가
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS workout_goal VARCHAR(20) 
DEFAULT 'hypertrophy' 
CHECK (workout_goal IN ('hypertrophy', 'strength'));

-- 기존 레코드에 기본값 설정
UPDATE profiles 
SET workout_goal = 'hypertrophy' 
WHERE workout_goal IS NULL;

