# Cyber Sentinels - Supabase Integration Setup Guide

## Overview
This guide explains how to configure and use the Supabase integration for the Cyber Sentinels website. The integration includes:
- **uploadResource()** - Upload files to Supabase Storage and save metadata
- **loadResources()** - Fetch and display resources from Supabase database

---

## Prerequisites

✅ Supabase project created  
✅ `resources` table with columns: `id`, `name`, `description`, `file_url`, `created_at`  
✅ `resources` storage bucket created and set to public  
✅ RLS policies configured

---

## Step 1: Get Your Supabase Credentials

### Find Your Project URL
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Click **Settings** → **API**
4. Copy the **Project URL** (looks like: `https://xxxxxxxxxxxxx.supabase.co`)

### Find Your Anon Key
1. In the same **Settings** → **API** page
2. Under "Project API keys", copy the **`anon` (public)** API key
   - ⚠️ Never use the `service_role` key in client-side code

---

## Step 2: Update Configuration in HTML Files

### Update `dashboard.html`
Find these lines (around line 820):
```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace with your actual credentials:
```javascript
const SUPABASE_URL = 'https://xxxxxxxxxxxxx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### Update `resources.html`
Find these lines (around line 236):
```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace with the **same credentials** as dashboard.html:
```javascript
const SUPABASE_URL = 'https://xxxxxxxxxxxxx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

---

## Step 3: Verify Database Schema

Your `resources` table should have these columns:

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | Primary key - auto-generated |
| `name` | text | Resource name |
| `description` | text | Resource description |
| `file_url` | text | Public URL from Storage |
| `created_at` | timestamp | Auto-filled with current time |

### Example SQL to create the table:
```sql
CREATE TABLE resources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

---

## Step 4: Configure Storage Bucket

1. Go to **Storage** in Supabase Dashboard
2. Make sure you have a `resources` bucket
3. **Important**: Set bucket to **Public** (not RLS-protected for reads)
4. Verify RLS policies allow public read access:
   ```sql
   -- Allow public read access
   CREATE POLICY "Allow public read" ON storage.objects
     FOR SELECT USING (bucket_id = 'resources');
   ```

---

## Step 5: Verify RLS Policies

### For `resources` table, you need policies like:

```sql
-- Allow anyone to read
CREATE POLICY "Allow public read" ON resources
  FOR SELECT USING (true);

-- Allow authenticated users to insert
CREATE POLICY "Allow authenticated insert" ON resources
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow users to delete their own
CREATE POLICY "Allow delete own" ON resources
  FOR DELETE USING (auth.uid()::text = id::text);
```

---

## How the Code Works

### uploadResource() Function (Dashboard)

**Triggered by:** Resource form submission on `dashboard.html`

**Flow:**
1. ✓ Validates form inputs and file size (max 50MB)
2. ✓ Gets file extension and generates unique filename using `crypto.randomUUID()`
3. ✓ Uploads file to `resources` storage bucket
4. ✓ Gets public URL from storage
5. ✓ Inserts metadata (name, description, file_url) into `resources` table
6. ✓ Shows success message and refreshes resource list

**Example Form HTML:**
```html
<form id="resource-form">
    <input type="text" id="resource-name" placeholder="Resource Name" required>
    <textarea id="resource-description" placeholder="Description"></textarea>
    <input type="file" id="resource-file" accept="..." required>
    <button type="submit" class="btn btn-primary">Upload Resource</button>
</form>
```

**Console Output Example:**
```
=== RESOURCE FORM SUBMITTED ===
Form data: {name: "Security Guide", description: "...", fileName: "guide.pdf"}
Generated unique filename: 550e8400-e29b-41d4-a716-446655440000.pdf
✓ File uploaded to Supabase Storage
✓ Public URL generated: https://xxxxxxxxxxxxx.supabase.co/storage/v1/object/public/resources/550e...
✓ Resource metadata saved to database
```

### loadResources() Function (Resources Page)

**Triggered by:** Page load on `resources.html`

**Flow:**
1. ✓ Fetches all resources from `resources` table (ordered by most recent first)
2. ✓ Creates HTML cards for each resource with:
   - Resource name
   - Description
   - Download button (links to file_url)
3. ✓ Shows empty state if no resources exist
4. ✓ Shows error message if fetch fails

**Console Output Example:**
```
=== LOADING RESOURCES FROM SUPABASE ===
✓ Resources loaded from Supabase: [{id: "uuid", name: "...", ...}, ...]
Total resources: 5
Creating resource cards for 5 resources
```

---

## Error Handling

### Console Logging

All functions include detailed console logging:
- `console.log()` - Success and info messages
- `console.error()` - Error messages with full error details

**Check browser console (F12 → Console tab) for:**
- Upload progress
- API errors
- Data validation errors
- Network issues

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `Supabase not initialized` | Missing credentials | Check SUPABASE_URL and SUPABASE_ANON_KEY |
| `Storage upload failed` | Bucket permissions | Verify bucket is public or RLS allows uploads |
| `File size exceeds 50MB limit` | File too large | Upload smaller file |
| `Database insert failed` | Table schema mismatch | Verify column names match exactly |

---

## Testing the Integration

### Test Upload (Dashboard)
1. Go to `dashboard.html`
2. Scroll to "📚 Add Resources" section
3. Fill in:
   - **Resource Name**: "Test Guide"
   - **Description**: "This is a test resource"
   - **File**: Select any file (PDF, image, document, etc.)
4. Click "Upload Resource"
5. Check browser console for messages
6. Should see:
   - ✓ Success message in UI
   - ✓ Console logs showing upload progress
   - ✓ Resource appears in "📦 Resources Library" section

### Test Load (Resources Page)
1. Go to `resources.html`
2. Resources should load automatically
3. Check browser console for:
   - Total resources count
   - Resource data from database
4. Verify cards display with download buttons

---

## Troubleshooting

### Resources Not Loading?

**Check:**
1. Browser DevTools Console (F12) for error messages
2. Supabase Dashboard → Logs for API errors
3. Verify Supabase credentials are correct
4. Confirm storage bucket is public
5. Check table has data: `SELECT * FROM resources;`

### Upload Failing?

**Check:**
1. File size under 50MB
2. Storage bucket exists and is public
3. Browser console for specific error message
4. Network tab shows request to Supabase (F12 → Network)

### Credentials Not Working?

**Verify:**
1. Copy fresh credentials from Supabase Dashboard
2. No extra spaces or line breaks in credentials
3. Using `anon` key, not `service_role` key
4. URL includes protocol (`https://`)

---

## File Structure

```
/home/dhanush/CS/
├── dashboard.html          ← uploadResource() function here
├── resources.html          ← loadResources() function here
└── SUPABASE_SETUP_GUIDE.md ← This file
```

---

## Quick Reference

### Form IDs & Input IDs

**Dashboard (dashboard.html):**
- Form: `#resource-form`
- Inputs: `#resource-name`, `#resource-description`, `#resource-file`
- Success Message: `#success-message`
- Error Message: `#error-message`

**Resources (resources.html):**
- Content Container: `#content`
- Uses Supabase client initialized in same file

### Key Variables

**Both Files:**
```javascript
SUPABASE_URL        // Your project URL
SUPABASE_ANON_KEY   // Your public API key
supabase            // Supabase client instance
```

### Important Constants

- **Max File Size**: 50 MB
- **Storage Bucket**: `resources`
- **Table Name**: `resources`
- **File Naming**: Uses `crypto.randomUUID()` for unique names

---

## Security Notes

✅ **Secure:**
- Using `anon` key (public, read/write limited by RLS)
- RLS policies restrict what authenticated users can do
- File names are randomized (UUID)
- XSS protection with `escapeHtml()` function

⚠️ **Important:**
- Never commit credentials to git
- Keep `service_role` key private (backend only)
- Regularly review RLS policies in Supabase Dashboard
- Monitor storage usage in Supabase Dashboard

---

## Additional Resources

- [Supabase JavaScript Documentation](https://supabase.com/docs/reference/javascript)
- [Supabase Storage Guide](https://supabase.com/docs/guides/storage)
- [Row Level Security (RLS)](https://supabase.com/docs/guides/auth/row-level-security)

---

## Support

If you encounter issues:
1. Check browser console (F12 → Console)
2. Check Supabase logs (Dashboard → Logs)
3. Verify all steps in this guide were completed
4. Try refreshing the page
5. Clear browser cache and cookies
