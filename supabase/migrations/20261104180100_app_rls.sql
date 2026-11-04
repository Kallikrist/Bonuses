-- BON-23: RLS for phone-OTP authenticated users.
-- Identity is auth.jwt() phone (E.164) matched to public.users."phoneNumber".
-- Do not use auth.uid() = users.id (local ids are not Auth UUIDs).
-- Do not use user_metadata. Does NOT drop tables or rows.
-- Drops insecure open policies only (anon USING true / WITH CHECK true).

CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.normalize_phone(p text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN p IS NULL OR btrim(p) = '' THEN NULL
    ELSE regexp_replace(p, '[^0-9]', '', 'g')
  END;
$$;

CREATE OR REPLACE FUNCTION private.auth_phone()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE(
    NULLIF((SELECT auth.jwt() ->> 'phone'), ''),
    (
      SELECT u.phone
      FROM auth.users u
      WHERE u.id = (SELECT auth.uid())
      LIMIT 1
    )
  );
$$;

CREATE OR REPLACE FUNCTION private.current_app_user_id()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT u.id
  FROM public.users u
  WHERE private.normalize_phone(u."phoneNumber")
        = private.normalize_phone(private.auth_phone())
    AND private.normalize_phone(private.auth_phone()) IS NOT NULL
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION private.current_company_ids()
RETURNS text[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE(
    (
      SELECT COALESCE(u."companyIds", '{}'::text[])
      FROM public.users u
      WHERE u.id = private.current_app_user_id()
    ),
    '{}'::text[]
  );
$$;

CREATE OR REPLACE FUNCTION private.is_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = private.current_app_user_id()
      AND u.role = 'superAdmin'
  );
$$;

CREATE OR REPLACE FUNCTION private.is_company_admin(p_company_id text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = private.current_app_user_id()
      AND (
        u.role = 'superAdmin'
        OR (
          p_company_id IS NOT NULL
          AND p_company_id = ANY (COALESCE(u."companyIds", '{}'::text[]))
          AND (
            u.role = 'admin'
            OR COALESCE(u."companyRoles" ->> p_company_id, '') = 'admin'
          )
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION private.in_company(p_company_id text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT private.is_super_admin()
      OR (
        p_company_id IS NOT NULL
        AND p_company_id = ANY (private.current_company_ids())
      );
$$;

CREATE OR REPLACE FUNCTION private.shares_companies(p_company_ids text[])
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT private.is_super_admin()
      OR (COALESCE(p_company_ids, '{}'::text[]) && private.current_company_ids());
$$;

CREATE OR REPLACE FUNCTION private.user_role(p_user_id text)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT u.role FROM public.users u WHERE u.id = p_user_id;
$$;

CREATE OR REPLACE FUNCTION private.user_company_ids(p_user_id text)
RETURNS text[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE(u."companyIds", '{}'::text[])
  FROM public.users u
  WHERE u.id = p_user_id;
$$;

REVOKE ALL ON SCHEMA private FROM PUBLIC, anon;
GRANT USAGE ON SCHEMA private TO authenticated;

REVOKE ALL ON FUNCTION private.normalize_phone(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.auth_phone() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.current_app_user_id() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.current_company_ids() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.is_super_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.is_company_admin(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.in_company(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.shares_companies(text[]) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.user_role(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.user_company_ids(text) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION private.normalize_phone(text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.auth_phone() TO authenticated;
GRANT EXECUTE ON FUNCTION private.current_app_user_id() TO authenticated;
GRANT EXECUTE ON FUNCTION private.current_company_ids() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_super_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_company_admin(text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.in_company(text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.shares_companies(text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION private.user_role(text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.user_company_ids(text) TO authenticated;

-- Insecure policies currently on the live project (anon/public USING true).
DROP POLICY IF EXISTS "Allow anon insert users" ON public.users;
DROP POLICY IF EXISTS "Allow anon update users" ON public.users;
DROP POLICY IF EXISTS "Allow anon updates to users totals" ON public.users;
DROP POLICY IF EXISTS "Users can insert own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can read own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can update received messages" ON public.messages;
DROP POLICY IF EXISTS "allow_insert_points_transactions_anon" ON public.points_transactions;
DROP POLICY IF EXISTS "allow_insert_points_tx_anon" ON public.points_transactions;
DROP POLICY IF EXISTS "allow_insert_sales_targets_anon" ON public.sales_targets;
DROP POLICY IF EXISTS "allow_select_sales_targets_anon" ON public.sales_targets;
DROP POLICY IF EXISTS "allow_update_sales_targets_anon" ON public.sales_targets;
DROP POLICY IF EXISTS "Allow all operations" ON public.test_table;
DROP POLICY IF EXISTS "Allow all operations for testing" ON public.test_table;

DROP POLICY IF EXISTS bonuses_users_select ON public.users;
DROP POLICY IF EXISTS bonuses_users_insert ON public.users;
DROP POLICY IF EXISTS bonuses_users_update ON public.users;
DROP POLICY IF EXISTS bonuses_companies_select ON public.companies;
DROP POLICY IF EXISTS bonuses_companies_insert ON public.companies;
DROP POLICY IF EXISTS bonuses_companies_update ON public.companies;
DROP POLICY IF EXISTS bonuses_workplaces_select ON public.workplaces;
DROP POLICY IF EXISTS bonuses_workplaces_write ON public.workplaces;
DROP POLICY IF EXISTS bonuses_targets_select ON public.sales_targets;
DROP POLICY IF EXISTS bonuses_targets_insert ON public.sales_targets;
DROP POLICY IF EXISTS bonuses_targets_update ON public.sales_targets;
DROP POLICY IF EXISTS bonuses_points_select ON public.points_transactions;
DROP POLICY IF EXISTS bonuses_points_insert ON public.points_transactions;
DROP POLICY IF EXISTS bonuses_bonuses_select ON public.bonuses;
DROP POLICY IF EXISTS bonuses_bonuses_insert ON public.bonuses;
DROP POLICY IF EXISTS bonuses_bonuses_update ON public.bonuses;
DROP POLICY IF EXISTS bonuses_bonuses_write ON public.bonuses;
DROP POLICY IF EXISTS bonuses_messages_select ON public.messages;
DROP POLICY IF EXISTS bonuses_messages_insert ON public.messages;
DROP POLICY IF EXISTS bonuses_messages_update ON public.messages;
DROP POLICY IF EXISTS bonuses_approvals_select ON public.approval_requests;
DROP POLICY IF EXISTS bonuses_approvals_insert ON public.approval_requests;
DROP POLICY IF EXISTS bonuses_approvals_update ON public.approval_requests;
DROP POLICY IF EXISTS bonuses_points_rules_select ON public.points_rules;
DROP POLICY IF EXISTS bonuses_points_rules_write ON public.points_rules;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users FORCE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies FORCE ROW LEVEL SECURITY;
ALTER TABLE public.workplaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workplaces FORCE ROW LEVEL SECURITY;
ALTER TABLE public.sales_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_targets FORCE ROW LEVEL SECURITY;
ALTER TABLE public.points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.points_transactions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.bonuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bonuses FORCE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages FORCE ROW LEVEL SECURITY;
ALTER TABLE public.approval_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approval_requests FORCE ROW LEVEL SECURITY;
ALTER TABLE public.points_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.points_rules FORCE ROW LEVEL SECURITY;
ALTER TABLE public.test_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_table FORCE ROW LEVEL SECURITY;

-- users: no unrestricted SELECT. Company peers + self + super-admin only.
CREATE POLICY bonuses_users_select ON public.users
  FOR SELECT TO authenticated
  USING (
    (SELECT private.is_super_admin())
    OR id = (SELECT private.current_app_user_id())
    OR (SELECT private.shares_companies("companyIds"))
  );

CREATE POLICY bonuses_users_insert ON public.users
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT private.is_super_admin())
    OR (
      role IS DISTINCT FROM 'superAdmin'
      AND COALESCE("companyIds", '{}'::text[]) <> '{}'::text[]
      AND NOT EXISTS (
        SELECT 1
        FROM unnest(COALESCE("companyIds", '{}'::text[])) AS cid
        WHERE NOT private.is_company_admin(cid)
      )
    )
  );

CREATE POLICY bonuses_users_update ON public.users
  FOR UPDATE TO authenticated
  USING (
    (SELECT private.is_super_admin())
    OR id = (SELECT private.current_app_user_id())
    OR (SELECT private.shares_companies("companyIds"))
  )
  WITH CHECK (
    (SELECT private.is_super_admin())
    OR (
      id = (SELECT private.current_app_user_id())
      AND role IS NOT DISTINCT FROM (SELECT private.user_role(id))
      AND COALESCE("companyIds", '{}'::text[])
          IS NOT DISTINCT FROM (SELECT private.user_company_ids(id))
    )
    OR (
      role IS DISTINCT FROM 'superAdmin'
      AND COALESCE("companyIds", '{}'::text[]) <> '{}'::text[]
      AND NOT EXISTS (
        SELECT 1
        FROM unnest(COALESCE("companyIds", '{}'::text[])) AS cid
        WHERE NOT private.is_company_admin(cid)
      )
    )
  );

CREATE POLICY bonuses_companies_select ON public.companies
  FOR SELECT TO authenticated
  USING (
    (SELECT private.is_super_admin())
    OR (SELECT private.in_company(id))
    OR "adminUserId" = (SELECT private.current_app_user_id())
    OR owner_id = (SELECT private.current_app_user_id())
  );

CREATE POLICY bonuses_companies_insert ON public.companies
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT private.is_super_admin())
    OR "adminUserId" = (SELECT private.current_app_user_id())
    OR owner_id = (SELECT private.current_app_user_id())
  );

CREATE POLICY bonuses_companies_update ON public.companies
  FOR UPDATE TO authenticated
  USING (
    (SELECT private.is_super_admin())
    OR (SELECT private.is_company_admin(id))
    OR "adminUserId" = (SELECT private.current_app_user_id())
  )
  WITH CHECK (
    (SELECT private.is_super_admin())
    OR (SELECT private.is_company_admin(id))
    OR "adminUserId" = (SELECT private.current_app_user_id())
  );

CREATE POLICY bonuses_workplaces_select ON public.workplaces
  FOR SELECT TO authenticated
  USING (
    (SELECT private.in_company(COALESCE(company_id, "companyId")))
  );

CREATE POLICY bonuses_workplaces_write ON public.workplaces
  FOR ALL TO authenticated
  USING (
    (SELECT private.is_company_admin(COALESCE(company_id, "companyId")))
  )
  WITH CHECK (
    (SELECT private.is_company_admin(COALESCE(company_id, "companyId")))
  );

CREATE POLICY bonuses_targets_select ON public.sales_targets
  FOR SELECT TO authenticated
  USING (
    (SELECT private.in_company(company_id))
    OR assigned_employee_id = (SELECT private.current_app_user_id())
    OR (SELECT private.current_app_user_id())
       = ANY (COALESCE(collaborative_employee_ids, '{}'::text[]))
  );

CREATE POLICY bonuses_targets_insert ON public.sales_targets
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT private.is_company_admin(company_id))
  );

CREATE POLICY bonuses_targets_update ON public.sales_targets
  FOR UPDATE TO authenticated
  USING (
    (SELECT private.is_company_admin(company_id))
    OR assigned_employee_id = (SELECT private.current_app_user_id())
    OR (SELECT private.current_app_user_id())
       = ANY (COALESCE(collaborative_employee_ids, '{}'::text[]))
  )
  WITH CHECK (
    (SELECT private.is_company_admin(company_id))
    OR assigned_employee_id = (SELECT private.current_app_user_id())
    OR (SELECT private.current_app_user_id())
       = ANY (COALESCE(collaborative_employee_ids, '{}'::text[]))
  );

CREATE POLICY bonuses_points_select ON public.points_transactions
  FOR SELECT TO authenticated
  USING (
    user_id = (SELECT private.current_app_user_id())
    OR (SELECT private.is_company_admin(company_id))
  );

CREATE POLICY bonuses_points_insert ON public.points_transactions
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = (SELECT private.current_app_user_id())
    OR (SELECT private.is_company_admin(company_id))
  );

CREATE POLICY bonuses_bonuses_select ON public.bonuses
  FOR SELECT TO authenticated
  USING (
    (SELECT private.in_company(COALESCE(company_id, "companyId")))
  );

CREATE POLICY bonuses_bonuses_insert ON public.bonuses
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT private.is_company_admin(COALESCE(company_id, "companyId")))
  );

CREATE POLICY bonuses_bonuses_update ON public.bonuses
  FOR UPDATE TO authenticated
  USING (
    (SELECT private.is_company_admin(COALESCE(company_id, "companyId")))
    OR (SELECT private.in_company(COALESCE(company_id, "companyId")))
  )
  WITH CHECK (
    (SELECT private.is_company_admin(COALESCE(company_id, "companyId")))
    OR (
      (SELECT private.in_company(COALESCE(company_id, "companyId")))
      AND COALESCE(redeemed_by, "redeemedBy")
          = (SELECT private.current_app_user_id())
    )
  );

CREATE POLICY bonuses_messages_select ON public.messages
  FOR SELECT TO authenticated
  USING (
    (SELECT private.is_super_admin())
    OR COALESCE(sender_id, "senderId") = (SELECT private.current_app_user_id())
    OR COALESCE(receiver_id, "recipientId") = (SELECT private.current_app_user_id())
  );

CREATE POLICY bonuses_messages_insert ON public.messages
  FOR INSERT TO authenticated
  WITH CHECK (
    COALESCE(sender_id, "senderId") = (SELECT private.current_app_user_id())
  );

CREATE POLICY bonuses_messages_update ON public.messages
  FOR UPDATE TO authenticated
  USING (
    COALESCE(receiver_id, "recipientId") = (SELECT private.current_app_user_id())
    OR COALESCE(sender_id, "senderId") = (SELECT private.current_app_user_id())
  )
  WITH CHECK (
    COALESCE(receiver_id, "recipientId") = (SELECT private.current_app_user_id())
    OR COALESCE(sender_id, "senderId") = (SELECT private.current_app_user_id())
  );

CREATE POLICY bonuses_approvals_select ON public.approval_requests
  FOR SELECT TO authenticated
  USING (
    (SELECT private.is_super_admin())
    OR COALESCE("submittedBy", user_id) = (SELECT private.current_app_user_id())
    OR (SELECT private.is_company_admin(company_id))
    OR EXISTS (
      SELECT 1
      FROM public.sales_targets t
      WHERE t.id = approval_requests."targetId"
        AND (
          (SELECT private.is_company_admin(t.company_id))
          OR t.assigned_employee_id = (SELECT private.current_app_user_id())
        )
    )
  );

CREATE POLICY bonuses_approvals_insert ON public.approval_requests
  FOR INSERT TO authenticated
  WITH CHECK (
    COALESCE("submittedBy", user_id) = (SELECT private.current_app_user_id())
  );

CREATE POLICY bonuses_approvals_update ON public.approval_requests
  FOR UPDATE TO authenticated
  USING (
    (SELECT private.is_company_admin(company_id))
    OR COALESCE("submittedBy", user_id) = (SELECT private.current_app_user_id())
  )
  WITH CHECK (
    (SELECT private.is_company_admin(company_id))
    OR COALESCE("submittedBy", user_id) = (SELECT private.current_app_user_id())
  );

CREATE POLICY bonuses_points_rules_select ON public.points_rules
  FOR SELECT TO authenticated
  USING ((SELECT private.in_company(company_id)));

CREATE POLICY bonuses_points_rules_write ON public.points_rules
  FOR ALL TO authenticated
  USING ((SELECT private.is_company_admin(company_id)))
  WITH CHECK ((SELECT private.is_company_admin(company_id)));

-- test_table stays in place (no DROP TABLE) but is locked: RLS on, no policies.

REVOKE ALL ON TABLE public.users FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.companies FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.workplaces FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.sales_targets FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.points_transactions FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.bonuses FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.messages FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.approval_requests FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.points_rules FROM anon, PUBLIC;
REVOKE ALL ON TABLE public.test_table FROM anon, authenticated, PUBLIC;

GRANT SELECT, INSERT, UPDATE ON TABLE public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.companies TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.workplaces TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.sales_targets TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.points_transactions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.bonuses TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.messages TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.approval_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.points_rules TO authenticated;

GRANT ALL ON TABLE public.users TO service_role;
GRANT ALL ON TABLE public.companies TO service_role;
GRANT ALL ON TABLE public.workplaces TO service_role;
GRANT ALL ON TABLE public.sales_targets TO service_role;
GRANT ALL ON TABLE public.points_transactions TO service_role;
GRANT ALL ON TABLE public.bonuses TO service_role;
GRANT ALL ON TABLE public.messages TO service_role;
GRANT ALL ON TABLE public.approval_requests TO service_role;
GRANT ALL ON TABLE public.points_rules TO service_role;
GRANT ALL ON TABLE public.test_table TO service_role;

-- Existing live views are SECURITY DEFINER and would bypass table RLS.
-- Flip to invoker (Postgres 15+) without dropping the views.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_views
    WHERE schemaname = 'public' AND viewname = 'user_company_points'
  ) THEN
    EXECUTE 'ALTER VIEW public.user_company_points SET (security_invoker = true)';
    EXECUTE 'REVOKE ALL ON TABLE public.user_company_points FROM anon, PUBLIC';
    EXECUTE 'GRANT SELECT ON TABLE public.user_company_points TO authenticated';
    EXECUTE 'GRANT ALL ON TABLE public.user_company_points TO service_role';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_views
    WHERE schemaname = 'public' AND viewname = 'sales_targets_active'
  ) THEN
    EXECUTE 'ALTER VIEW public.sales_targets_active SET (security_invoker = true)';
    EXECUTE 'REVOKE ALL ON TABLE public.sales_targets_active FROM anon, PUBLIC';
    EXECUTE 'GRANT SELECT ON TABLE public.sales_targets_active TO authenticated';
    EXECUTE 'GRANT ALL ON TABLE public.sales_targets_active TO service_role';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'approve_sales_target'
  ) THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.approve_sales_target(text, text, integer) FROM PUBLIC, anon';
  END IF;
END $$;
