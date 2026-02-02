-- planned_workouts 테이블에 색상 컬럼 추가
ALTER TABLE planned_workouts 
ADD COLUMN IF NOT EXISTS color_hex VARCHAR(20) DEFAULT '0xFF2196F3';

-- 기존 레코드에 기본값 설정
UPDATE planned_workouts 
SET color_hex = '0xFF2196F3' 
WHERE color_hex IS NULL;

