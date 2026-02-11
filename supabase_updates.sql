-- 1. 무료 체험(Free Trial) 로직을 위해 profiles 테이블에 가입일(created_at) 컬럼 추가
-- (기존 데이터 호환을 위해 없으면 추가하고, 기본값은 현재 시간으로 설정)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- (참고: 필요하다면 auth.users의 created_at 데이터를 마이그레이션 해야 할 수 있음)

-- 2. 프리미엄 권한 회수(Revoke Premium)를 위한 RPC 함수 생성
CREATE OR REPLACE FUNCTION admin_revoke_premium(target_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 보안 체크: 요청자가 진짜 관리자(is_admin = true)인지 확인
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Access Denied: 관리자 권한이 없습니다.';
  END IF;

  -- 로직: 대상 유저의 프리미엄 상태 제거 및 만료일 초기화
  UPDATE public.profiles
  SET is_premium = false,
      premium_until = null
  WHERE id = target_id;
END;
$$;
