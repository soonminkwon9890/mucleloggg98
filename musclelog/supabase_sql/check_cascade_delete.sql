-- Cascade Delete 설정 확인 및 수정 스크립트
-- 이 스크립트는 exercise_baselines 삭제 시 workout_sets가 자동으로 삭제되도록 보장합니다.

-- 1. 현재 외래 키 제약 조건 확인
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
    ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'workout_sets'
    AND kcu.column_name = 'baseline_id';

-- 2. Cascade Delete 설정 (필요한 경우에만 실행)
-- 위 쿼리 결과에서 delete_rule이 'CASCADE'가 아니라면 아래 코드를 실행하세요.

-- 기존 외래 키 제약 조건 삭제
ALTER TABLE workout_sets 
DROP CONSTRAINT IF EXISTS workout_sets_baseline_id_fkey;

-- Cascade Delete가 적용된 새로운 외래 키 제약 조건 추가
ALTER TABLE workout_sets 
ADD CONSTRAINT workout_sets_baseline_id_fkey 
  FOREIGN KEY (baseline_id) 
  REFERENCES exercise_baselines(id) 
  ON DELETE CASCADE;

-- 3. 설정 확인 (다시 실행하여 delete_rule이 'CASCADE'인지 확인)
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
    ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'workout_sets'
    AND kcu.column_name = 'baseline_id';

-- 예상 결과: delete_rule = 'CASCADE'

