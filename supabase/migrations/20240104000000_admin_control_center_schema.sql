-- ========================================================
-- PARIDHAN SUPER ADMIN CONTROL CENTER & AUDIT LOGS SCHEMA
-- Migration #004: Comprehensive Admin Management & Security
-- ========================================================

-- 1. Create Admin Audit Logs Table
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  admin_name text NOT NULL DEFAULT 'Super Admin',
  admin_email text NOT NULL DEFAULT 'admin@paridhan.app',
  action text NOT NULL, -- e.g. 'KYC_APPROVED', 'KYC_REJECTED', 'SELLER_SUSPENDED', 'REFUND_PROCESSED', 'COMMISSION_UPDATED', 'SENSITIVE_DATA_ACCESSED'
  entity text NOT NULL, -- e.g. 'shop', 'order', 'user', 'advertisement', 'delivery_partner', 'kyc'
  entity_id text NOT NULL,
  details text,
  previous_value jsonb,
  new_value jsonb,
  ip_address text DEFAULT '127.0.0.1',
  user_agent text DEFAULT 'PARIDHAN Admin Console',
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indices for audit query performance
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.admin_audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON public.admin_audit_logs(entity, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.admin_audit_logs(created_at DESC);

-- Enable RLS for Audit Logs
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super Admins can view audit logs"
  ON public.admin_audit_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Super Admins can insert audit logs"
  ON public.admin_audit_logs FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 2. Ensure detailed KYC fields on shops table
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS pan_number text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS aadhaar_number text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS bank_account_number text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS bank_ifsc text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS bank_name text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS business_reg_number text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS gstin text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS kyc_notes text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS kyc_rejection_reason text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS kyc_submitted_at timestamptz;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS kyc_verified_at timestamptz;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS license_document_url text;
