# Supabase Storage Setup for Profile Pictures

## Overview
This guide helps you set up Supabase Storage for storing member profile pictures.

## Step 1: Create the Storage Bucket

1. Go to your Supabase Dashboard
2. Navigate to **Storage** in the left sidebar
3. Click **Create a new bucket**
4. Configure as follows:
   - **Name**: `profile-pictures`
   - **Public bucket**: ✅ Yes (toggle ON)
   - Click **Create bucket**

## Step 2: Set Up Row Level Security (RLS) Policies

Go to the **Storage** section and click the bucket name `profile-pictures` to edit policies.

### Policy 1: Users can upload to their own folder
- **Name**: `Users can upload own profile pictures`
- **Definition Type**: For authenticated users
- **Allowed operation**: INSERT
- **Target roles**: All users (default)
- **Policy expression**: 
  ```sql
  (bucket_id = 'profile-pictures' AND (storage.foldername(name))[1] = auth.uid()::text)
  ```

### Policy 2: Users can delete from their own folder
- **Name**: `Users can delete own profile pictures`
- **Definition Type**: For authenticated users
- **Allowed operation**: DELETE
- **Target roles**: All users (default)
- **Policy expression**:
  ```sql
  (bucket_id = 'profile-pictures' AND (storage.foldername(name))[1] = auth.uid()::text)
  ```

### Policy 3: Public read access
- **Name**: `Public read profile pictures`
- **Definition Type**: For all users
- **Allowed operation**: SELECT
- **Target roles**: All users (default)
- **Policy expression**:
  ```sql
  (bucket_id = 'profile-pictures')
  ```

## Step 3: Add profile_picture_url Column (if not already added)

If you're updating an existing database, run this SQL in your Supabase SQL Editor:

```sql
-- Add profile_picture_url column to profiles table
alter table profiles 
add column if not exists profile_picture_url text;

-- Add comment
comment on column profiles.profile_picture_url is 'URL to user profile picture in storage';
```

## Step 4: Test the Setup

### Upload a Profile Picture:
1. Go to member-dashboard.html (as a logged-in member)
2. Click the profile avatar in the top-right
3. The avatar image should pop up for clicking
4. Select an image file (JPG, PNG, GIF, or WebP)
5. Click "📷 Change Picture" button
6. Image should upload and display in both:
   - Profile page avatar
   - Navbar profile button

### Verify File Storage:
1. In Supabase Dashboard → Storage → profile-pictures
2. You should see a folder with your user UUID
3. Inside that folder, you'll see your profile picture file

### Check Database:
1. In Supabase Dashboard → SQL Editor
2. Run: `SELECT id, full_name, profile_picture_url FROM profiles LIMIT 5;`
3. You should see the profile picture URL for the uploaded image

## Step 5: Update Existing Profiles (Optional)

If you already have existing profile records and want to add the column:

```sql
-- This adds the column if it doesn't exist
alter table if exists profiles 
add column if not exists profile_picture_url text;

-- Verify the column was added
select column_name, data_type from information_schema.columns 
where table_name = 'profiles' and column_name like '%picture%';
```

## Troubleshooting

### "Storage bucket not found" error
- Go to Storage in Supabase Dashboard
- Make sure `profile-pictures` bucket exists
- Verify it's set to **Public**

### "Permission denied" when uploading
- Check RLS policies are set correctly
- Verify user is authenticated (check localStorage for userType)
- Make sure policy expressions are correct (check for typos)

### Image not displaying
- Check the browser console for errors (F12)
- Verify the URL is accessible by opening it in a new tab
- Make sure image file size is under 5MB
- Check supported formats: JPG, PNG, GIF, WebP

### Old images not deleting
- The app tries to delete old images, but might fail silently
- You can manually delete from Storage → profile-pictures bucket
- Check console logs for delete operation status

## File Storage Path Structure

Profile pictures are stored with this path structure:
```
profile-pictures/
└── {user_uuid}/
    └── {user_uuid}-{timestamp}.jpg
```

Example:
```
profile-pictures/
└── 550e8400-e29b-41d4-a716-446655440000/
    └── 550e8400-e29b-41d4-a716-446655440000-1699564800000.jpg
```

## Image Upload Specifications

- **Supported Formats**: JPG, PNG, GIF, WebP
- **Maximum Size**: 5MB (5,242,880 bytes)
- **Max Dimensions**: No limit (browser may handle large images)
- **Recommended Size**: 300x300px or larger
- **Cache Control**: 3600 seconds (1 hour)

## FAQ

**Q: Can users change their profile picture multiple times?**
- Yes! The app automatically deletes the old image and uploads the new one.

**Q: Is my profile picture private?**
- No, profile pictures are public (anyone can view the URL). They're used for leaderboard and profile display.

**Q: What if the upload fails?**
- The app will show an error message. The file input is cleared automatically.
- If upload partially succeeds (image stored but database not updated), manually delete from Storage.

**Q: Can I set a profile picture size limit?**
- Yes, edit the `uploadProfilePicture()` function in member-dashboard.html
- Change the `maxSize` variable (currently 5MB)

**Q: Will my old profile pictures be deleted?**
- Yes, automatically! When you upload a new picture, all old pictures in your folder are deleted.
- The app tries to keep only the current profile picture in storage.

## Related Files

- [member-dashboard.html](member-dashboard.html) - Contains upload function
- [SUPABASE_MEMBER_SQL_SETUP.sql](SUPABASE_MEMBER_SQL_SETUP.sql) - Database schema with profile_picture_url column
- [credentials.js](credentials.js) - Supabase configuration

## Next Steps

1. Complete this setup in Supabase
2. Test profile picture upload on member dashboard
3. Verify pictures display in navbar and dropdown
4. Test on multiple accounts
5. Check storage usage in Supabase Dashboard

