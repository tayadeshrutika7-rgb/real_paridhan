-- Migration: 20240105000000_notifications_role_isolation.sql
-- Description: Strict role and platform isolation for notifications across Customer, Seller, Delivery, and Admin.

-- 1. Ensure user_role column exists on notifications table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'notifications' 
        AND column_name = 'role'
    ) THEN
        ALTER TABLE public.notifications 
        ADD COLUMN role user_role NOT NULL DEFAULT 'consumer';
    END IF;
END $$;

-- 2. Add category column for granular filtering
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'notifications' 
        AND column_name = 'category'
    ) THEN
        ALTER TABLE public.notifications 
        ADD COLUMN category text NOT NULL DEFAULT 'general';
    END IF;
END $$;

-- 3. Add payload jsonb column for rich metadata
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'notifications' 
        AND column_name = 'payload'
    ) THEN
        ALTER TABLE public.notifications 
        ADD COLUMN payload jsonb NOT NULL DEFAULT '{}'::jsonb;
    END IF;
END $$;

-- 4. Create composite indices for fast role-scoped queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_role_read 
ON public.notifications(user_id, role, read, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_role_category 
ON public.notifications(role, category);

-- 5. Row Level Security Policies for Strict Role Isolation
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view and update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Notifications permissive" ON public.notifications;
DROP POLICY IF EXISTS "Role-isolated notifications access" ON public.notifications;

-- Strict policy: users can only select/insert/update notifications targeted to their user_id AND active role (or admins)
CREATE POLICY "Role-isolated notifications access"
ON public.notifications
FOR ALL
USING (
    (
        auth.uid() = user_id 
        AND (
            role = 'consumer'
            OR role = (auth.jwt()->>'user_role')::user_role
            OR public.is_admin()
        )
    )
    OR public.is_admin()
)
WITH CHECK (
    auth.uid() = user_id OR public.is_admin()
);
