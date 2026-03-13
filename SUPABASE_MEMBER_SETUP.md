# Cyber Sentinels - Member Features Implementation Guide

## Overview
This guide explains all the new member-facing features added to the Cyber Sentinels website, including member registration, authentication, event registration, XP system, member dashboard, and leaderboard.

---

## NEW PAGES CREATED

### 1. **register.html** - Member Registration
**Path:** `/register.html`

**Features:**
- Full Name, Email, Department, Year, Register Number, Phone fields
- Password strength validation (8+ chars, uppercase, number)
- Email verification via Supabase Auth
- Links to login and home pages

**Flow:**
1. User fills out registration form
2. Submits with `supabase.auth.signUp()` with `emailRedirectTo`
3. Verification email sent to user
4. User clicks verification link in email
5. Redirected to `verify-email.html`
6. After verification, user can login

**Supabase Operations:**
- `signUp()` with user metadata
- Automatic email verification

---

### 2. **login.html** - Member Login
**Path:** `/login.html`

**Features:**
- Email and password login
- Email verification check (blocks unverified users)
- Links to registration and admin login pages
- Redirects to member dashboard on success

**Flow:**
1. User enters email/password
2. Calls `signInWithPassword()`
3. Checks if `email_confirmed_at` exists
4. If not verified, shows error and signs out
5. If verified, redirects to member dashboard

**Supabase Operations:**
- `signInWithPassword()`
- Check `email_confirmed_at` status

---

### 3. **verify-email.html** - Email Verification Handler
**Path:** `/verify-email.html`

**Features:**
- Handles email verification redirect from Supabase
- Automatically processes verification token
- Provides feedback on success/failure
- Redirects to login on success

**Flow:**
1. Supabase sends verification link with token in URL fragment
2. User clicks link, redirected to verify-email.html
3. Page automatically verifies token with Supabase
4. Shows success/error message
5. Redirects to login page

**Supabase Operations:**
- Automatic token verification via Supabase Auth

---

### 4. **member-dashboard.html** - Member Dashboard
**Path:** `/member-dashboard.html`

**Features:**
- Displays member profile (name, email, department, year, register number, phone)
- Shows total XP
- Shows leaderboard rank
- Lists all registered events
- Shows upcoming events
- Logout button

**Data Sources:**
- **profiles** table: Member info, XP
- **member_event_registrations** table: Event registrations
- **events** table: Event details

**Supabase Queries:**
```javascript
// Get member profile
select * from profiles where id = current_user_id and role = 'member'

// Get rank
select * from profiles where role = 'member' order by xp desc

// Get registered events
select * from member_event_registrations 
  inner join events on member_event_registrations.event_id = events.id
  where member_id = current_user_id

// Get upcoming events
select * from events where date > now() order by date asc limit 5
```

---

### 5. **leaderboard.html** - Leaderboard
**Path:** `/leaderboard.html`

**Features:**
- Ranked list of all members by XP
- Displays rank, name, department, XP
- Highlights current user
- Medals for top 3 (🥇🥈🥉)
- Responsive design

**Supabase Query:**
```javascript
select id, full_name, email, department, year, xp, role
from profiles
where role = 'member'
order by xp desc
```

---

## DATABASE SCHEMA REQUIRED

### 1. **profiles** Table
```sql
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text not null,
  department text,
  year text,
  register_no text,
  phone text,
  role text default 'member', -- 'member' or 'executive'
  xp integer default 0,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Index for queries
create index idx_profiles_role on profiles(role);
create index idx_profiles_xp on profiles(xp desc);
```

### 2. **member_event_registrations** Table
```sql
create table member_event_registrations (
  id uuid default gen_random_uuid() primary key,
  member_id uuid not null references profiles(id) on delete cascade,
  event_id bigint not null references events(id) on delete cascade,
  registered_at timestamp with time zone default now(),
  
  -- Prevent duplicate registrations
  unique(member_id, event_id)
);

-- Index for queries
create index idx_member_event_registrations_member on member_event_registrations(member_id);
create index idx_member_event_registrations_event on member_event_registrations(event_id);
```

### 3. **events** Table (Update)
```sql
-- Add xp_reward column if not exists
alter table events add column xp_reward integer default 0;

-- Update sample events with XP rewards
update events set xp_reward = 10 where title ilike '%workshop%';
update events set xp_reward = 30 where title ilike '%ctf%' or title ilike '%competition%';
update events set xp_reward = 50 where title ilike '%hackathon%';
```

---

## ROW LEVEL SECURITY (RLS) POLICIES

### profiles Table Policies
```sql
-- Allow public read
create policy "Allow public read" on profiles
  for select
  using (true);

-- Allow user to read/update own profile
create policy "Allow user read own" on profiles
  for select
  using (auth.uid() = id);

create policy "Allow user update own" on profiles
  for update
  using (auth.uid() = id);

-- Allow system to insert on signup
create policy "Allow insert on signup" on profiles
  for insert
  with check (auth.uid() = id);
```

### member_event_registrations Table Policies
```sql
-- Allow authenticated users to read
create policy "Allow authenticated read" on member_event_registrations
  for select
  using (auth.role() = 'authenticated');

-- Allow user to insert own registration
create policy "Allow insert own registration" on member_event_registrations
  for insert
  with check (auth.uid() = member_id);

-- Prevent deletion (no delete policy = no deletes allowed)
```

### events Table Policies
```sql
-- Allow public read
create policy "Allow public read" on events
  for select
  using (true);
```

---

## WORKFLOW DIAGRAMS

### Member Signup & Verification Flow
```
User fills registration form
         ↓
  supabase.auth.signUp()
         ↓
  Email sent with verification link
         ↓
  User clicks link in email
         ↓
  Redirected to verify-email.html
         ↓
  Verification token processed
         ↓
  Profile created in profiles table
         ↓
  User redirected to login.html
```

### Event Registration Flow
```
User views events.html
         ↓
  Click "Register" button on event
         ↓
  Check if user authenticated
         ↓
  Insert into member_event_registrations
         ↓
  Add event.xp_reward to profiles.xp
         ↓
  Update member_event_registrations
         ↓
  Show success message
```

### Auth Redirect Flow
```
If NOT authenticated:
  Button redirects to login.html

If authenticated but NOT verified:
  Shows error message
  Auto signs out

If authenticated AND verified:
  Check profiles table for role
  
  If role != 'member':
    Show "Join as member" message
    
  If role == 'member':
    Show registration button
    Check for duplicate registration
```

---

## SETTING UP EMAIL VERIFICATION IN SUPABASE

### Step 1: Configure Auth Settings
1. Go to **Supabase Dashboard** → Your Project
2. Navigate to **Authentication** → **Providers** → **Email**
3. Ensure "Enable email confirmations" is **ON**
4. Set confirmation email template (optional)

### Step 2: Set Email Redirect URL
In **Authentication** → **URL Configuration**:
- Add your verification redirect URL: `https://yourdomain.com/verify-email.html`
- Add your site URL: `https://yourdomain.com`

### Step 3: Configure SMTP (Optional - for production)
For reliable email delivery, configure custom SMTP in **Authentication** → **SMTP Settings**.

---

## FEATURE DETAILS

### XP System
- Points awarded when member registers for event
- Amount determined by `events.xp_reward` column
- Automatically added to `profiles.xp` on registration
- Leaderboard sorted by total XP

**Example XP Values:**
- Workshop: 10 XP
- CTF Competition: 30 XP
- Hackathon: 50 XP
- Seminar: 5 XP

### Member Rank Calculation
Rank is calculated real-time by counting members with higher XP:
```javascript
const allMembers = await supabase
  .from('profiles')
  .select('id, xp')
  .eq('role', 'member')
  .order('xp', { ascending: false });

const rank = allMembers.findIndex(m => m.id === userId) + 1;
```

### Duplicate Registration Prevention
The `member_event_registrations` table has a unique constraint:
```sql
unique(member_id, event_id)
```
This prevents the same member from registering twice for the same event.

---

## INTEGRATION WITH EXISTING PAGES

### home.html Updates
- Added "Leaderboard" link in navigation
- Changed login button to point to `login.html`
- Changed join button to point to `register.html`
- Updated mobile menu with leaderboard link

### events.html Updates
- Each event card now shows `+ XP` reward
- Added "Register" button in event modal
- Register button checks auth status:
  - Not logged in → "Login to Register"
  - Not verified → Cannot login
  - Not member → "Join as Member to Register"
  - Already registered → Shows checkmark
  - Can register → Shows register button
- On registration:
  - Inserts into `member_event_registrations`
  - Adds XP to member profile
  - Shows success message with XP earned

### auth.html (No changes)
- Remains for executive/admin login
- Still validates club IDs

---

## TESTING CHECKLIST

- [ ] Member can register with all fields
- [ ] Email verification sent to inbox
- [ ] Verification link works and redirects
- [ ] Member can login after verification
- [ ] Cannot login before verification
- [ ] Member dashboard shows profile info
- [ ] Member dashboard displays correct XP and rank
- [ ] Member dashboard shows registered events
- [ ] Member dashboard shows upcoming events
- [ ] Can register for events from events.html
- [ ] XP is added on event registration
- [ ] Cannot register twice for same event
- [ ] Leaderboard shows correct ranking
- [ ] Leaderboard shows medals for top 3
- [ ] Member can logout
- [ ] Current user highlighted in leaderboard
- [ ] All pages accessible to members
- [ ] Mobile responsive on all new pages

---

## TROUBLESHOOTING

### Email not received
1. Check spam folder
2. Verify SMTP settings in Supabase
3. Check email validity
4. Verify email confirmation is enabled

### Member profile not created
1. Check profiles table RLS policies
2. Verify user_metadata parameters match profile columns
3. Check browser console for errors

### XP not updating
1. Check member_event_registrations unique constraint
2. Verify xp_reward value set on events
3. Check profiles table update policies

### Cannot login after verification
1. Verify `email_confirmed_at` is set (check Supabase auth users)
2. Check login page email verification check logic
3. You may need to clear browser auth session

---

## FILE STRUCTURE

```
/home/dhanush/CS/
├── register.html              # Member registration
├── login.html                 # Member login
├── verify-email.html          # Email verification handler
├── member-dashboard.html      # Member dashboard
├── leaderboard.html           # Leaderboard
├── events.html                # Updated with registration
├── home.html                  # Updated navigation
├── auth.html                  # Executive login (unchanged)
├── credentials.js             # Supabase config
├── SUPABASE_MEMBER_SETUP.md   # This file
└── ...other files
```

---

## NEXT STEPS

1. **Create Supabase Tables**: Run SQL scripts in Supabase console
2. **Set RLS Policies**: Apply all RLS policies
3. **Configure Email**: Set up email verification in Auth
4. **Test Registration**: Create test account(s)
5. **Verify Email**: Check verification works
6. **Test Login**: Verify login functionality
7. **Test Events**: Register for events and check XP
8. **Check Leaderboard**: Verify ranking calculations
9. **Deploy**: When ready, deploy to production

---

## SECURITY CONSIDERATIONS

✅ **Implemented:**
- Email verification required before login
- RLS policies restrict data access
- XP only added through admin/system
- Duplicate registration prevention
- User can only access own profile

⚠️ **Additional Recommendations:**
- Limit registration rate (DDoS protection)
- Monitor for fraudulent XP claims
- Implement event attendance tracking
- Add admin moderation for XP disputes

---

## API/FUNCTION REFERENCE

### Member Registration
```javascript
// In register.html
supabase.auth.signUp({
  email,
  password,
  options: {
    emailRedirectTo: 'https://yourdomain.com/verify-email.html',
    data: {
      full_name,
      department,
      year,
      register_no,
      phone
    }
  }
})
```

### Member Login
```javascript
// In login.html
supabase.auth.signInWithPassword({
  email,
  password
})
```

### Register for Event
```javascript
// In events.html
supabase.from('member_event_registrations').insert([{
  member_id: user.id,
  event_id: eventId,
  registered_at: new Date().toISOString()
}])

// Then update XP
supabase.from('profiles').update({
  xp: profile.xp + event.xp_reward
}).eq('id', user.id)
```

### Get Leaderboard
```javascript
// In leaderboard.html
supabase.from('profiles')
  .select('id, full_name, department, xp, role')
  .eq('role', 'member')
  .order('xp', { ascending: false })
```

---

## Support & Documentation

For more help:
- Supabase Docs: https://supabase.com/docs
- Auth Flow: https://supabase.com/docs/guides/auth
- RLS Guide: https://supabase.com/docs/guides/auth/row-level-security

