-- 운동 삭제 연쇄 삭제 함수 (트랜잭션 처리 및 보안 강화)
-- 이 SQL 스크립트를 Supabase SQL Editor에서 실행하세요.

CREATE OR REPLACE FUNCTION delete_exercise_cascade(
  p_baseline_id UUID,
  p_exercise_name TEXT,
  p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 보안 검증: 사용자 소유 확인
  IF NOT EXISTS (
    SELECT 1 FROM exercise_baselines
    WHERE id = p_baseline_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION '운동을 찾을 수 없거나 권한이 없습니다.';
  END IF;
  
  -- 트랜잭션 시작 (함수 내부는 자동 트랜잭션)
  
  -- Step 1: workout_sets 삭제 (해당 운동의 모든 기록 삭제)
  DELETE FROM workout_sets
  WHERE baseline_id = p_baseline_id;
  
  -- Step 2: check_points 삭제 (관련 체크포인트 삭제)
  DELETE FROM check_points
  WHERE baseline_id = p_baseline_id;
  
  -- Step 3: routine_items 삭제 (exercise_name이 일치하는 모든 루틴 아이템 삭제)
  -- [중요] baseline_id가 아닌 exercise_name으로 매칭
  -- [보안] 해당 루틴이 사용자 소유인지 확인
  DELETE FROM routine_items
  WHERE exercise_name = p_exercise_name
    AND routine_id IN (
      SELECT id FROM routines WHERE user_id = p_user_id
    );
  
  -- Step 4: exercise_baselines 삭제 (원본 운동 데이터 삭제)
  -- [보안] WHERE 조건에 user_id 검증 포함
  DELETE FROM exercise_baselines
  WHERE id = p_baseline_id AND user_id = p_user_id;
  
  -- 트랜잭션 커밋 (함수 종료 시 자동)
END;
$$;

-- 함수 실행 권한 부여 (필요 시)
-- GRANT EXECUTE ON FUNCTION delete_exercise_cascade(UUID, TEXT, UUID) TO authenticated;

