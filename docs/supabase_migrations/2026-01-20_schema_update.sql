-- MuscleLog Supabase schema update (2026-01-20)
-- NOTE: 이 파일은 앱에서 자동 실행되지 않습니다.
-- Supabase SQL Editor에서 개발자가 직접 실행해야 합니다.

-- 1) 타겟 근육 컬럼 추가 (기본값: 빈 배열) - Null 에러 방지
ALTER TABLE exercise_baselines ADD COLUMN target_muscles text[] DEFAULT '{}';

-- 2) 레거시 컬럼 삭제 (MovementType 제거)
ALTER TABLE exercise_baselines DROP COLUMN movement_type;
ALTER TABLE routine_items DROP COLUMN movement_type;


