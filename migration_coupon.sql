-- 1. profiles 테이블에 'is_coupon_available' 컬럼 추가
-- 기본값 TRUE: 신규 및 기존 비구독 유저에게 혜택 제공
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_coupon_available BOOLEAN DEFAULT TRUE;

-- (선택) 데이터 정합성: 이미 프리미엄인 유저는 쿠폰을 사용할 필요가 없으므로 FALSE로 설정
UPDATE public.profiles
SET is_coupon_available = FALSE
WHERE is_premium = TRUE;

-- 2. 쿠폰 활성화 RPC 함수 생성 (안전장치 포함)
CREATE OR REPLACE FUNCTION activate_free_trial_coupon(target_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 보안 1: 본인 확인
  IF auth.uid() != target_id THEN
    RAISE EXCEPTION 'Access Denied: 본인만 활성화 가능합니다.';
  END IF;

  -- 보안 2: 이미 유효한 프리미엄(결제 등)이 있는 경우 방지 (기간 단축 사고 예방)
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = target_id AND is_premium = true AND premium_until > NOW()) THEN
    RAISE EXCEPTION 'Already Premium: 이미 프리미엄 구독 중입니다.';
  END IF;

  -- 체크: 쿠폰 보유 여부
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = target_id AND is_coupon_available = true) THEN
    RAISE EXCEPTION 'No Coupon: 사용할 수 있는 쿠폰이 없습니다.';
  END IF;

  -- 실행: 프리미엄 부여 및 쿠폰 소모
  UPDATE public.profiles
  SET is_premium = true,
      premium_until = NOW() + INTERVAL '7 days',
      is_coupon_available = false
  WHERE id = target_id;
END;
$$;
