-- ==============================================================================
-- Migration: 20240106000000_shop_and_delivery_kyc_expansion.sql
-- Description: Expand Shop & Delivery Partner KYC fields (GSTIN, PAN, License, Trade License, etc.)
-- ==============================================================================

-- 1. Expand Shops table with business verification fields
ALTER TABLE public.shops
  ADD COLUMN IF NOT EXISTS gstin text,
  ADD COLUMN IF NOT EXISTS pan_number text,
  ADD COLUMN IF NOT EXISTS business_type text DEFAULT 'sole_proprietorship',
  ADD COLUMN IF NOT EXISTS trade_license_number text,
  ADD COLUMN IF NOT EXISTS aadhaar_number text,
  ADD COLUMN IF NOT EXISTS bank_account_name text,
  ADD COLUMN IF NOT EXISTS pincode text,
  ADD COLUMN IF NOT EXISTS landmark text,
  ADD COLUMN IF NOT EXISTS kyc_documents text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS kyc_rejection_reason text,
  ADD COLUMN IF NOT EXISTS kyc_notes text,
  ADD COLUMN IF NOT EXISTS kyc_verified_at timestamptz;

-- 2. Expand Delivery Partner Profile table with onboarding verification fields
ALTER TABLE public.delivery_partner_profile
  ADD COLUMN IF NOT EXISTS full_name text,
  ADD COLUMN IF NOT EXISTS phone text,
  ADD COLUMN IF NOT EXISTS email text,
  ADD COLUMN IF NOT EXISTS driving_license_number text,
  ADD COLUMN IF NOT EXISTS vehicle_rc_number text,
  ADD COLUMN IF NOT EXISTS pan_number text,
  ADD COLUMN IF NOT EXISTS aadhaar_number text,
  ADD COLUMN IF NOT EXISTS upi_id text,
  ADD COLUMN IF NOT EXISTS emergency_contact_name text,
  ADD COLUMN IF NOT EXISTS emergency_contact_phone text,
  ADD COLUMN IF NOT EXISTS kyc_documents text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS kyc_rejection_reason text,
  ADD COLUMN IF NOT EXISTS kyc_notes text,
  ADD COLUMN IF NOT EXISTS verified_at timestamptz;

-- 3. Create index for fast admin KYC pending searches
CREATE INDEX IF NOT EXISTS idx_shops_kyc_status ON public.shops(kyc_status);
CREATE INDEX IF NOT EXISTS idx_delivery_partner_verification ON public.delivery_partner_profile(verification_status);

COMMENT ON COLUMN public.shops.gstin IS 'Goods and Services Tax Identification Number (15 alphanumeric characters)';
COMMENT ON COLUMN public.shops.pan_number IS '10-character Permanent Account Number of shop owner or business';
COMMENT ON COLUMN public.delivery_partner_profile.driving_license_number IS 'Valid Indian Driving License number for motor vehicles';
