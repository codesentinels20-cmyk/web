-- ============================================
-- CYBER SENTINELS - SUPABASE SETUP SQL
-- ============================================
-- Run these SQL commands in your Supabase console
-- to configure the database for member features

-- Enable required extensions
create extension if not exists "uuid-ossp";

-- ============================================
-- 1. CREATE PROFILES TABLE
-- ============================================
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  department text,
  year text,
  register_no text,
  phone text,
  role text default 'member' check (role in ('member', 'executive')),
  xp integer default 0,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create indexes for performance
create index if not exists idx_profiles_role on profiles(role);
create index if not exists idx_profiles_xp on profiles(xp desc);
create index if not exists idx_profiles_email on profiles(email);

-- Add table comment
comment on table profiles is 'User profiles for club members and executives';
comment on column profiles.xp is 'Experience points earned from event participation';

-- ============================================
-- 2. CREATE MEMBER EVENT REGISTRATIONS TABLE
-- ============================================
create table if not exists member_event_registrations (
  id uuid default gen_random_uuid() primary key,
  member_id uuid not null references profiles(id) on delete cascade,
  event_id bigint not null references events(id) on delete cascade,
  registered_at timestamp with time zone default now(),
  
  -- Prevent duplicate registrations for same member & event
  constraint unique_member_event unique(member_id, event_id)
);

-- Create indexes for performance
create index if not exists idx_member_event_registrations_member on member_event_registrations(member_id);
create index if not exists idx_member_event_registrations_event on member_event_registrations(event_id);
create index if not exists idx_member_event_registrations_created on member_event_registrations(registered_at);

-- Add table comment
comment on table member_event_registrations is 'Tracks which members have registered for which events';

-- ============================================
-- 3. UPDATE EVENTS TABLE (IF NEEDED)
-- ============================================
-- xp_reward column already exists, skipping add column
-- If you need to reset xp_reward values, uncomment below:
-- update events set xp_reward = 0 where xp_reward is null;

-- Add indexes if not exists
create index if not exists idx_events_date on events(event_date);
create index if not exists idx_events_xp_reward on events(xp_reward);

-- ============================================
-- 4. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================
alter table profiles enable row level security;
alter table member_event_registrations enable row level security;

-- ============================================
-- 5. PROFILES TABLE RLS POLICIES
-- ============================================

-- Allow anyone to read profiles (for leaderboard)
create policy "Allow public read profiles" 
  on profiles for select 
  using (true);

-- Allow users to read their own profile
create policy "Users can read own profile" 
  on profiles for select 
  using (auth.uid() = id);

-- Allow users to update their own profile
create policy "Users can update own profile" 
  on profiles for update 
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Allow system to insert profiles on signup
-- Note: You may want to use a trigger instead for more control
create policy "Allow insert own profile" 
  on profiles for insert 
  with check (auth.uid() = id);

-- ============================================
-- 6. MEMBER EVENT REGISTRATIONS RLS POLICIES
-- ============================================

-- Allow authenticated users to read registrations
create policy "Allow authenticated read registrations" 
  on member_event_registrations for select 
  using (auth.role() = 'authenticated');

-- Allow users to read their own registrations
create policy "Users can read own registrations" 
  on member_event_registrations for select 
  using (auth.uid() = member_id);

-- Allow users to insert their own registrations
create policy "Users can register for events" 
  on member_event_registrations for insert 
  with check (auth.uid() = member_id);

-- Note: No delete policy = no one can delete registrations (immutable)

-- ============================================
-- 7. CREATE TRIGGER FOR PROFILE AUTO-INSERT (OPTIONAL)
-- ============================================
-- This trigger automatically creates a profile when a user signs up
-- Only run if you're not using custom signup logic

create or replace function create_profile_on_signup()
returns trigger as $$
begin
  insert into profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.user_metadata->>'full_name', 'Member'),
    'member'
  )
  on conflict (id) do nothing;
  
  return new;
end;
$$ language plpgsql security definer;

-- Drop trigger if exists and recreate
drop trigger if exists on_auth_user_signup on auth.users;

create trigger on_auth_user_signup
  after insert on auth.users
  for each row
  execute procedure create_profile_on_signup();

-- ============================================
-- 8. SAMPLE DATA (OPTIONAL)
-- ============================================
-- Add sample XP rewards for different event types
-- Update these if you have actual events

-- Workshop events: 10 XP
-- UPDATE events SET xp_reward = 10 WHERE title ILIKE '%workshop%';

-- CTF / Competition events: 30 XP
-- UPDATE events SET xp_reward = 30 WHERE title ILIKE '%ctf%' OR title ILIKE '%competition%';

-- Hackathon events: 50 XP
-- UPDATE events SET xp_reward = 50 WHERE title ILIKE '%hackathon%';

-- General talks/seminars: 5 XP
-- UPDATE events SET xp_reward = 5 WHERE xp_reward = 0;

-- ============================================
-- 9. VERIFICATION QUERIES
-- ============================================
-- Run these to verify your setup

-- Check profiles table
-- select * from profiles limit 5;

-- Check member_event_registrations table
-- select * from member_event_registrations limit 5;

-- Check RLS policies
-- select * from pg_policies where tablename = 'profiles';
-- select * from pg_policies where tablename = 'member_event_registrations';

-- Check events with XP
-- select id, title, xp_reward from events where xp_reward > 0 limit 5;

-- ============================================
-- IMPORTANT NOTES
-- ============================================
/*

1. EMAIL VERIFICATION SETUP:
   - Go to Authentication → Providers → Email
   - Enable "Enable email confirmations"
   - Configure email template (optional)
   
2. REDIRECT URL SETUP:
   - Go to Authentication → URL Configuration
   - Add: https://yourdomain.com/verify-email.html (Redirect URL)
   - Add: https://yourdomain.com (Site URL)
   
3. CUSTOM SMTP (Optional, for production):
   - Go to Authentication → SMTP Settings
   - Configure custom email provider
   
4. TESTING:
   - Register at: /register.html
   - Check email for verification link
   - Click link to verify
   - Login at: /login.html
   - Go to events and register for an event
   - Check /member-dashboard.html for XP
   - Check /leaderboard.html for ranking
   
5. USER METADATA:
   - When users sign up, additional data is stored in user_metadata
   - This is available during profile creation via trigger

6. RLS SECURITY:
   - All policies are designed to prevent unauthorized access
   - Users can only access their own profiles for modification
   - Public read on profiles allows leaderboard display
   - Registrations can only be inserted by the user themselves

7. PRODUCTION CHECKLIST:
   - [ ] Test email verification with real email
   - [ ] Test XP calculation with multiple events
   - [ ] Test duplicate registration prevention
   - [ ] Verify leaderboard ranking
   - [ ] Test on mobile devices
   - [ ] Check RLS policies are working
   - [ ] Set up error monitoring/logging

*/

-- ============================================
-- END OF SETUP SCRIPT
-- ============================================
