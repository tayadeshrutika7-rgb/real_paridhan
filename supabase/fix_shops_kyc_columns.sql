-- ==============================================================================
-- ADD COMPLETE KYC & BANKING COLUMNS TO SHOPS TABLE
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/faqtswmhgintutwvnkyy/sql/new
-- ==============================================================================

ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS owner_name text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS contact_phone text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS contact_email text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS bank_account_number text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS bank_ifsc text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS bank_name text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS bank_account_name text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS gstin text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS pan_number text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS business_type text DEFAULT 'sole_proprietorship';
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS trade_license_number text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS aadhaar_number text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS pincode text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS landmark text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS kyc_documents text[] DEFAULT '{}';
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS kyc_rejection_reason text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS kyc_notes text;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS kyc_verified_at timestamptz;
