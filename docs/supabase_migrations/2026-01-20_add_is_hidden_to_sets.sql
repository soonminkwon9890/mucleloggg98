-- MuscleLog Supabase schema update (2026-01-20)
-- NOTE: 이 파일은 앱에서 자동 실행되지 않습니다.
-- Supabase SQL Editor에서 개발자가 직접 실행해야 합니다.

-- 1) workout_sets 테이블에 is_hidden 컬럼 추가 (기본값: false)
ALTER TABLE workout_sets ADD COLUMN is_hidden boolean DEFAULT false;

-- 2) NULL 값 정리 (기존 데이터에 대해)
UPDATE workout_sets SET is_hidden = false WHERE is_hidden IS NULL;

