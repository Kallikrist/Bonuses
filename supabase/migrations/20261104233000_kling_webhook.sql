-- BON-41: Kling webhook ingest. Additive only. Does NOT drop tables or rows.
-- Owner applies; not auto-applied. Service-role Edge Function writes only.
-- ISK amounts are integers as-is (never x100).

CREATE TABLE IF NOT EXISTS public.kling_webhook_events (
  id text PRIMARY KEY,
  type text NOT NULL,
  environment text,
  delivery_id text,
  payload jsonb NOT NULL,
  processed boolean NOT NULL DEFAULT false,
  processed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.kling_webhook_events ADD COLUMN IF NOT EXISTS type text;
ALTER TABLE public.kling_webhook_events ADD COLUMN IF NOT EXISTS environment text;
ALTER TABLE public.kling_webhook_events ADD COLUMN IF NOT EXISTS delivery_id text;
ALTER TABLE public.kling_webhook_events ADD COLUMN IF NOT EXISTS payload jsonb;
ALTER TABLE public.kling_webhook_events ADD COLUMN IF NOT EXISTS processed boolean NOT NULL DEFAULT false;
ALTER TABLE public.kling_webhook_events ADD COLUMN IF NOT EXISTS processed_at timestamptz;
ALTER TABLE public.kling_webhook_events ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

CREATE TABLE IF NOT EXISTS public.kling_subscriptions (
  id text PRIMARY KEY,
  company_id text,
  status text NOT NULL DEFAULT 'unknown',
  paid boolean NOT NULL DEFAULT false,
  access_revoked boolean NOT NULL DEFAULT false,
  cancel_at_period_end boolean NOT NULL DEFAULT false,
  amount_isk integer,
  currency text NOT NULL DEFAULT 'ISK',
  period_start timestamptz,
  period_end timestamptz,
  last_payment_intent_id text,
  last_event_id text,
  last_event_type text,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS company_id text;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS status text;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS paid boolean NOT NULL DEFAULT false;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS access_revoked boolean NOT NULL DEFAULT false;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS cancel_at_period_end boolean NOT NULL DEFAULT false;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS amount_isk integer;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS currency text;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS period_start timestamptz;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS period_end timestamptz;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS last_payment_intent_id text;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS last_event_id text;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS last_event_type text;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS metadata jsonb;
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE public.kling_subscriptions ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS kling_subscriptions_company_id_idx
  ON public.kling_subscriptions (company_id);

ALTER TABLE public.kling_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kling_subscriptions ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.kling_webhook_events FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.kling_subscriptions FROM PUBLIC, anon, authenticated;
GRANT ALL ON TABLE public.kling_webhook_events TO postgres, service_role;
GRANT ALL ON TABLE public.kling_subscriptions TO postgres, service_role;
