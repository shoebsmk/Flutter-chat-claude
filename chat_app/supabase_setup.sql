-- 1. Create the users table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  username TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS Policies
-- Allow anyone to read profiles
CREATE POLICY "Public profiles are viewable by everyone." 
ON public.users FOR SELECT 
USING (true);

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile." 
ON public.users FOR UPDATE 
USING (auth.uid() = id);

-- 4. Create the Trigger Function
-- This function will be called whenever a new user is created in auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, username)
  VALUES (
    new.id, 
    new.raw_user_meta_data->>'username' -- Extract username from metadata
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create the Trigger
-- Drop if exists to avoid errors on multiple runs
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 6. Backfill existing users (Run this once to fix missing users)
-- Inserts missing users from auth.users into public.users
INSERT INTO public.users (id, username)
SELECT id, raw_user_meta_data->>'username'
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.users);
