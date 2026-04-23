-- =============================================
-- APP VERSIONS TABLE
-- Stores version information for app updates
-- =============================================

CREATE TABLE IF NOT EXISTS public.app_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version TEXT NOT NULL, -- e.g., '1.0.1'
    build_number INTEGER NOT NULL UNIQUE, -- Incremental build number (e.g., 5)
    min_build_number INTEGER DEFAULT 0, -- Minimum build number required to use the app (users below this will be forced to update)
    release_notes TEXT, -- Release notes / changelog
    download_url TEXT, -- URL to download the update (optional, uses store URL if null)
    is_active BOOLEAN NOT NULL DEFAULT TRUE, -- Is this version currently active?
    is_force_update BOOLEAN NOT NULL DEFAULT FALSE, -- Is this a force update?
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read version info (public catalog)
CREATE POLICY "app_versions_select_all" ON public.app_versions
    FOR SELECT
    USING (true);

-- Only authenticated admins can insert/update/delete versions
CREATE POLICY "app_versions_manage_authenticated" ON public.app_versions
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "app_versions_update_authenticated" ON public.app_versions
    FOR UPDATE
    USING (auth.role() = 'authenticated');

CREATE POLICY "app_versions_delete_authenticated" ON public.app_versions
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- =============================================
-- SAMPLE DATA
-- =============================================

-- Insert a sample version entry (update this when you release a new version)
INSERT INTO public.app_versions (version, build_number, min_build_number, release_notes, is_active, is_force_update)
VALUES (
    '1.0.1',
    2,
    0,
    '🎉 New Features:
• Fixed location accuracy issues
• Improved store loading performance
• Smaller, more compact toast notifications
• Various bug fixes and improvements

Thank you for using Queless!',
    true,
    false
);
