-- Profile Editing Feature Migration
-- Run this script in your Supabase SQL Editor

-- 1. Add avatar_url column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 2. Add bio column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS bio TEXT;

-- 3. Add updated_at column for tracking profile updates
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now());

-- 4. Create index for avatar_url queries (if needed for search/filtering)
CREATE INDEX IF NOT EXISTS idx_users_avatar_url 
ON public.users(avatar_url) 
WHERE avatar_url IS NOT NULL;

-- 5. Add constraint for bio length (max 500 characters)
ALTER TABLE public.users 
ADD CONSTRAINT check_bio_length CHECK (bio IS NULL OR LENGTH(bio) <= 500);

-- 6. Add constraint for username length (max 50 characters, min 3)
-- Note: min length constraint already exists from previous setup, adding max length
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'check_username_length'
  ) THEN
    ALTER TABLE public.users 
    ADD CONSTRAINT check_username_length CHECK (LENGTH(username) >= 3 AND LENGTH(username) <= 50);
  END IF;
END $$;

-- 7. Add unique constraint on username (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_username_key'
  ) THEN
    ALTER TABLE public.users 
    ADD CONSTRAINT users_username_key UNIQUE (username);
  END IF;
END $$;

-- 8. Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 9. Create trigger to update updated_at on user updates
DROP TRIGGER IF EXISTS trigger_update_users_updated_at ON public.users;
CREATE TRIGGER trigger_update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_users_updated_at();

-- 10. Create storage bucket for profile pictures
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

-- 11. Storage policy: Users can upload their own profile picture
DROP POLICY IF EXISTS "Users can upload own profile picture" ON storage.objects;
CREATE POLICY "Users can upload own profile picture"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-pictures' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 12. Storage policy: Users can update their own profile picture
DROP POLICY IF EXISTS "Users can update own profile picture" ON storage.objects;
CREATE POLICY "Users can update own profile picture"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-pictures' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 13. Storage policy: Users can delete their own profile picture
DROP POLICY IF EXISTS "Users can delete own profile picture" ON storage.objects;
CREATE POLICY "Users can delete own profile picture"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-pictures' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 14. Storage policy: Anyone can view profile pictures (public bucket)
DROP POLICY IF EXISTS "Anyone can view profile pictures" ON storage.objects;
CREATE POLICY "Anyone can view profile pictures"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-pictures');

