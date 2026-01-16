-- is_hidden_from_home 컬럼 추가 (Smart Delete 기능 지원)
-- 홈 화면에서 숨김 처리된 운동을 보관함에서만 볼 수 있게 함

ALTER TABLE exercise_baselines 
ADD COLUMN IF NOT EXISTS is_hidden_from_home BOOLEAN DEFAULT FALSE;

-- 기존 데이터에 대한 기본값 설정 (이미 있는 운동들은 모두 표시)
UPDATE exercise_baselines 
SET is_hidden_from_home = FALSE 
WHERE is_hidden_from_home IS NULL;

-- 인덱스 추가 (홈 화면 조회 성능 향상)
CREATE INDEX IF NOT EXISTS idx_exercise_baselines_hidden 
ON exercise_baselines(user_id, is_hidden_from_home, created_at DESC);

-- 확인 쿼리
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'exercise_baselines' 
AND column_name = 'is_hidden_from_home';

