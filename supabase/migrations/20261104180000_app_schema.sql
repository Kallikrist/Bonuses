-- BON-23: additive schema for Flutter SupabaseService dual-write.
-- Matches live project hkpkznslzkgnijoahggn (text ids, mixed camelCase /
-- snake_case columns from Dart toJson + service payloads).
-- Does NOT drop tables, columns, or rows.

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
  id text PRIMARY KEY,
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  role text NOT NULL DEFAULT 'employee',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  "createdAt" timestamptz DEFAULT now(),
  "phoneNumber" text,
  "companyIds" text[] DEFAULT '{}'::text[],
  "companyNames" text[] DEFAULT '{}'::text[],
  "companyPoints" jsonb DEFAULT '{}'::jsonb,
  "companyRoles" jsonb DEFAULT '{}'::jsonb,
  "primaryCompanyId" text,
  "workplaceIds" text[] DEFAULT '{}'::text[],
  "workplaceNames" text[] DEFAULT '{}'::text[],
  "totalPoints" integer DEFAULT 0
);

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS name text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS email text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS role text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "createdAt" timestamptz DEFAULT now();
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "phoneNumber" text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "companyIds" text[];
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "companyNames" text[];
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "companyPoints" jsonb;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "companyRoles" jsonb;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "primaryCompanyId" text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "workplaceIds" text[];
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "workplaceNames" text[];
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "totalPoints" integer DEFAULT 0;

-- SupabaseService.getUsersByCompany filters on snake_case company_ids.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'company_ids'
  ) THEN
    ALTER TABLE public.users
      ADD COLUMN company_ids text[] GENERATED ALWAYS AS (COALESCE("companyIds", '{}'::text[])) STORED;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- companies
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.companies (
  id text PRIMARY KEY,
  name text NOT NULL,
  owner_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  address text,
  "contactEmail" text,
  "contactPhone" text,
  "createdAt" timestamptz DEFAULT now(),
  "employeeCount" text,
  "isActive" boolean DEFAULT true,
  "subscriptionId" text,
  "adminUserId" text
);

ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS name text;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS owner_id text;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS address text;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS "contactEmail" text;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS "contactPhone" text;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS "createdAt" timestamptz DEFAULT now();
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS "employeeCount" text;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT true;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS "subscriptionId" text;
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS "adminUserId" text;

-- ---------------------------------------------------------------------------
-- workplaces
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.workplaces (
  id text PRIMARY KEY,
  company_id text,
  name text NOT NULL,
  address text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  "companyId" text,
  "createdAt" timestamptz DEFAULT now()
);

ALTER TABLE public.workplaces ADD COLUMN IF NOT EXISTS company_id text;
ALTER TABLE public.workplaces ADD COLUMN IF NOT EXISTS name text;
ALTER TABLE public.workplaces ADD COLUMN IF NOT EXISTS address text;
ALTER TABLE public.workplaces ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.workplaces ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE public.workplaces ADD COLUMN IF NOT EXISTS "companyId" text;
ALTER TABLE public.workplaces ADD COLUMN IF NOT EXISTS "createdAt" timestamptz DEFAULT now();

-- ---------------------------------------------------------------------------
-- sales_targets (snake_case payload from SupabaseService)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sales_targets (
  id text PRIMARY KEY,
  company_id text,
  assigned_employee_id text,
  collaborative_employee_ids text[] DEFAULT '{}'::text[],
  title text,
  description text,
  target_amount numeric,
  points numeric DEFAULT 0,
  date date,
  status text DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  actual_amount numeric DEFAULT 0,
  is_met boolean DEFAULT false,
  percentage_above_target numeric DEFAULT 0,
  points_awarded integer DEFAULT 0,
  created_by text,
  assigned_employee_name text,
  assigned_workplace_id text,
  assigned_workplace_name text,
  collaborative_employee_names text[] DEFAULT '{}'::text[],
  is_submitted boolean DEFAULT false,
  is_approved boolean DEFAULT false,
  approved_by text,
  approved_at timestamptz,
  deleted_at timestamptz,
  deleted_by text
);

ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS company_id text;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS assigned_employee_id text;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS collaborative_employee_ids text[] DEFAULT '{}'::text[];
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS title text;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS target_amount numeric;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS points numeric DEFAULT 0;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS date date;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS status text DEFAULT 'pending';
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS actual_amount numeric DEFAULT 0;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS is_met boolean DEFAULT false;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS percentage_above_target numeric DEFAULT 0;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS points_awarded integer DEFAULT 0;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS created_by text;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS assigned_employee_name text;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS assigned_workplace_id text;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS assigned_workplace_name text;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS collaborative_employee_names text[] DEFAULT '{}'::text[];
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS is_submitted boolean DEFAULT false;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS is_approved boolean DEFAULT false;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS approved_by text;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS approved_at timestamptz;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS deleted_at timestamptz;
ALTER TABLE public.sales_targets ADD COLUMN IF NOT EXISTS deleted_by text;

-- ---------------------------------------------------------------------------
-- points_transactions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.points_transactions (
  id text PRIMARY KEY,
  user_id text,
  company_id text,
  amount numeric,
  description text,
  date timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  type text,
  points numeric,
  related_target_id text
);

ALTER TABLE public.points_transactions ADD COLUMN IF NOT EXISTS user_id text;
ALTER TABLE public.points_transactions ADD COLUMN IF NOT EXISTS company_id text;
ALTER TABLE public.points_transactions ADD COLUMN IF NOT EXISTS amount numeric;
ALTER TABLE public.points_transactions ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE public.points_transactions ADD COLUMN IF NOT EXISTS date timestamptz DEFAULT now();
ALTER TABLE public.points_transactions ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.points_transactions ADD COLUMN IF NOT EXISTS type text;
ALTER TABLE public.points_transactions ADD COLUMN IF NOT EXISTS points numeric;
ALTER TABLE public.points_transactions ADD COLUMN IF NOT EXISTS related_target_id text;

-- ---------------------------------------------------------------------------
-- bonuses (Dart toJson uses snake_case; live also has camelCase copies)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bonuses (
  id text PRIMARY KEY,
  company_id text,
  title text,
  description text,
  points_required numeric,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  "pointsRequired" integer,
  status text,
  "createdAt" timestamptz,
  "redeemedAt" timestamptz,
  "redeemedBy" text,
  "giftCardCode" text,
  "secretCode" text,
  "companyId" text,
  gift_card_code text,
  secret_code text,
  redeemed_at timestamptz,
  redeemed_by text
);

ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS company_id text;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS title text;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS points_required numeric;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS "pointsRequired" integer;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS status text;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS "createdAt" timestamptz;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS "redeemedAt" timestamptz;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS "redeemedBy" text;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS "giftCardCode" text;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS "secretCode" text;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS "companyId" text;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS gift_card_code text;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS secret_code text;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS redeemed_at timestamptz;
ALTER TABLE public.bonuses ADD COLUMN IF NOT EXISTS redeemed_by text;

-- ---------------------------------------------------------------------------
-- messages
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.messages (
  id text PRIMARY KEY,
  sender_id text,
  receiver_id text,
  company_id text,
  content text,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  "senderId" text,
  "recipientId" text,
  "companyId" text,
  "isRead" boolean,
  "timestamp" timestamptz
);

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS sender_id text;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS receiver_id text;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS company_id text;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS content text;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS "senderId" text;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS "recipientId" text;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS "companyId" text;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS "isRead" boolean;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS "timestamp" timestamptz;

-- ---------------------------------------------------------------------------
-- approval_requests
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.approval_requests (
  id text PRIMARY KEY,
  user_id text,
  company_id text,
  type text,
  status text DEFAULT 'pending',
  submitted_at timestamptz DEFAULT now(),
  approved_at timestamptz,
  created_at timestamptz DEFAULT now(),
  "targetId" text,
  "submittedBy" text,
  "submittedByName" text,
  "submittedAt" timestamptz,
  "reviewedAt" timestamptz,
  "reviewedBy" text,
  "reviewedByName" text,
  "rejectionReason" text,
  "newActualAmount" numeric,
  "previousActualAmount" numeric,
  "newTeamMemberIds" text[],
  "newTeamMemberNames" text[],
  "previousTeamMemberIds" text[],
  "previousTeamMemberNames" text[]
);

ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS user_id text;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS company_id text;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS type text;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS status text DEFAULT 'pending';
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS submitted_at timestamptz DEFAULT now();
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS approved_at timestamptz;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "targetId" text;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "submittedBy" text;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "submittedByName" text;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "submittedAt" timestamptz;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "reviewedAt" timestamptz;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "reviewedBy" text;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "reviewedByName" text;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "rejectionReason" text;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "newActualAmount" numeric;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "previousActualAmount" numeric;
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "newTeamMemberIds" text[];
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "newTeamMemberNames" text[];
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "previousTeamMemberIds" text[];
ALTER TABLE public.approval_requests ADD COLUMN IF NOT EXISTS "previousTeamMemberNames" text[];

-- ---------------------------------------------------------------------------
-- points_rules (present on the live project; not written by SupabaseService)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.points_rules (
  company_id text PRIMARY KEY,
  entries jsonb DEFAULT '[]'::jsonb,
  point_value numeric DEFAULT 100,
  currency_symbol text DEFAULT 'ISK',
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.points_rules ADD COLUMN IF NOT EXISTS entries jsonb DEFAULT '[]'::jsonb;
ALTER TABLE public.points_rules ADD COLUMN IF NOT EXISTS point_value numeric DEFAULT 100;
ALTER TABLE public.points_rules ADD COLUMN IF NOT EXISTS currency_symbol text DEFAULT 'ISK';
ALTER TABLE public.points_rules ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Copy camelCase keys the Flutter toJson sends into the snake_case columns
-- the service queries. Same-row assignment only — no deletes.
CREATE OR REPLACE FUNCTION public.sync_dual_write_columns()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF TG_TABLE_NAME = 'workplaces' THEN
    NEW.company_id := COALESCE(NEW.company_id, NEW."companyId");
    NEW."companyId" := COALESCE(NEW."companyId", NEW.company_id);
    NEW.created_at := COALESCE(NEW.created_at, NEW."createdAt", now());
    NEW."createdAt" := COALESCE(NEW."createdAt", NEW.created_at);
  ELSIF TG_TABLE_NAME = 'messages' THEN
    NEW.sender_id := COALESCE(NEW.sender_id, NEW."senderId");
    NEW."senderId" := COALESCE(NEW."senderId", NEW.sender_id);
    NEW.receiver_id := COALESCE(NEW.receiver_id, NEW."recipientId");
    NEW."recipientId" := COALESCE(NEW."recipientId", NEW.receiver_id);
    NEW.company_id := COALESCE(NEW.company_id, NEW."companyId");
    NEW."companyId" := COALESCE(NEW."companyId", NEW.company_id);
    NEW.is_read := COALESCE(NEW.is_read, NEW."isRead", false);
    NEW."isRead" := COALESCE(NEW."isRead", NEW.is_read);
    NEW.created_at := COALESCE(NEW.created_at, NEW."timestamp", now());
  ELSIF TG_TABLE_NAME = 'approval_requests' THEN
    NEW.user_id := COALESCE(NEW.user_id, NEW."submittedBy");
    NEW."submittedBy" := COALESCE(NEW."submittedBy", NEW.user_id);
    NEW.submitted_at := COALESCE(NEW.submitted_at, NEW."submittedAt", now());
    NEW."submittedAt" := COALESCE(NEW."submittedAt", NEW.submitted_at);
  ELSIF TG_TABLE_NAME = 'companies' THEN
    NEW.owner_id := COALESCE(NEW.owner_id, NEW."adminUserId");
    NEW."adminUserId" := COALESCE(NEW."adminUserId", NEW.owner_id);
    NEW.created_at := COALESCE(NEW.created_at, NEW."createdAt", now());
    NEW."createdAt" := COALESCE(NEW."createdAt", NEW.created_at);
  ELSIF TG_TABLE_NAME = 'bonuses' THEN
    NEW.company_id := COALESCE(NEW.company_id, NEW."companyId");
    NEW."companyId" := COALESCE(NEW."companyId", NEW.company_id);
    NEW.secret_code := COALESCE(NEW.secret_code, NEW."secretCode");
    NEW."secretCode" := COALESCE(NEW."secretCode", NEW.secret_code);
    NEW.gift_card_code := COALESCE(NEW.gift_card_code, NEW."giftCardCode");
    NEW."giftCardCode" := COALESCE(NEW."giftCardCode", NEW.gift_card_code);
    NEW.redeemed_by := COALESCE(NEW.redeemed_by, NEW."redeemedBy");
    NEW."redeemedBy" := COALESCE(NEW."redeemedBy", NEW.redeemed_by);
    NEW.redeemed_at := COALESCE(NEW.redeemed_at, NEW."redeemedAt");
    NEW."redeemedAt" := COALESCE(NEW."redeemedAt", NEW.redeemed_at);
    NEW.created_at := COALESCE(NEW.created_at, NEW."createdAt", now());
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_workplaces ON public.workplaces;
CREATE TRIGGER trg_sync_workplaces
  BEFORE INSERT OR UPDATE ON public.workplaces
  FOR EACH ROW EXECUTE PROCEDURE public.sync_dual_write_columns();

DROP TRIGGER IF EXISTS trg_sync_messages ON public.messages;
CREATE TRIGGER trg_sync_messages
  BEFORE INSERT OR UPDATE ON public.messages
  FOR EACH ROW EXECUTE PROCEDURE public.sync_dual_write_columns();

DROP TRIGGER IF EXISTS trg_sync_approval_requests ON public.approval_requests;
CREATE TRIGGER trg_sync_approval_requests
  BEFORE INSERT OR UPDATE ON public.approval_requests
  FOR EACH ROW EXECUTE PROCEDURE public.sync_dual_write_columns();

DROP TRIGGER IF EXISTS trg_sync_companies ON public.companies;
CREATE TRIGGER trg_sync_companies
  BEFORE INSERT OR UPDATE ON public.companies
  FOR EACH ROW EXECUTE PROCEDURE public.sync_dual_write_columns();

DROP TRIGGER IF EXISTS trg_sync_bonuses ON public.bonuses;
CREATE TRIGGER trg_sync_bonuses
  BEFORE INSERT OR UPDATE ON public.bonuses
  FOR EACH ROW EXECUTE PROCEDURE public.sync_dual_write_columns();

REVOKE ALL ON FUNCTION public.sync_dual_write_columns() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sync_dual_write_columns() TO authenticated;

CREATE INDEX IF NOT EXISTS idx_users_phone_digits
  ON public.users (regexp_replace(COALESCE("phoneNumber", ''), '[^0-9]', '', 'g'));
CREATE INDEX IF NOT EXISTS idx_users_company_ids_gin
  ON public.users USING gin ("companyIds");
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users (role);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users (email);

CREATE INDEX IF NOT EXISTS idx_companies_admin
  ON public.companies ("adminUserId");

CREATE INDEX IF NOT EXISTS idx_workplaces_company
  ON public.workplaces (company_id);

CREATE INDEX IF NOT EXISTS idx_sales_targets_company
  ON public.sales_targets (company_id);
CREATE INDEX IF NOT EXISTS idx_sales_targets_assigned
  ON public.sales_targets (assigned_employee_id);
CREATE INDEX IF NOT EXISTS idx_sales_targets_collab_gin
  ON public.sales_targets USING gin (collaborative_employee_ids);
CREATE INDEX IF NOT EXISTS idx_sales_targets_date
  ON public.sales_targets (date);

CREATE INDEX IF NOT EXISTS idx_points_tx_user
  ON public.points_transactions (user_id);
CREATE INDEX IF NOT EXISTS idx_points_tx_company
  ON public.points_transactions (company_id);

CREATE INDEX IF NOT EXISTS idx_bonuses_company
  ON public.bonuses (company_id);

CREATE INDEX IF NOT EXISTS idx_messages_sender
  ON public.messages (sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver
  ON public.messages (receiver_id);

CREATE INDEX IF NOT EXISTS idx_approval_submitted
  ON public.approval_requests ("submittedBy");
CREATE INDEX IF NOT EXISTS idx_approval_company
  ON public.approval_requests (company_id);
