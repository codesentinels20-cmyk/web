# Supabase Integration - Quick Code Reference

## Core Functions

### uploadResource() - File Upload & Database Insert
**Location:** `dashboard.html` (lines ~900-980)

**What it does:**
- Takes file from form input
- Uploads to Supabase Storage bucket `resources`
- Generates unique filename using `crypto.randomUUID()`
- Gets public URL
- Inserts metadata into `resources` table
- Shows success/error message

**Triggered by:**
```javascript
document.getElementById('resource-form').addEventListener('submit', async (e) => { ... })
```

**Form Fields Required:**
- `#resource-name` (text input)
- `#resource-description` (textarea)
- `#resource-file` (file input)

**Database Insert Fields:**
```javascript
{
  name: string,           // from #resource-name
  description: string,    // from #resource-description
  file_url: string,       // generated public URL
  created_at: timestamp   // auto-filled by Supabase
}
```

**Error Handling:**
- Validates form inputs exist
- Checks file size (max 50MB)
- Catches Supabase storage errors
- Catches database insert errors
- Displays user-friendly error messages

**Console Output:**
```
=== RESOURCE FORM SUBMITTED ===
Form data: { name, description, fileName }
Generated unique filename: [UUID].[ext]
✓ File uploaded to Supabase Storage: [path]
✓ Public URL generated: [file_url]
✓ Resource metadata saved to database
```

---

### loadResources() - Fetch & Display
**Location:** `resources.html` (lines ~245-315)

**What it does:**
- Fetches all records from `resources` table
- Orders by `created_at` (newest first)
- Creates HTML cards for each resource
- Displays name, description, download button
- Shows empty state if no resources

**Triggered by:**
```javascript
window.addEventListener('load', () => {
    loadResources();
});
```

**Database Query:**
```javascript
const { data: resources, error } = await supabase
    .from('resources')
    .select('*')
    .order('created_at', { ascending: false });
```

**Card HTML Template:**
```html
<div class="resource-card">
    <div class="resource-name">${resource.name}</div>
    <div class="resource-description">${resource.description}</div>
    <a href="${resource.file_url}" download class="download-btn">⬇️ Download File</a>
</div>
```

**Error Handling:**
- Catches database query errors
- Displays error message in UI
- Logs detailed error to console

**Console Output:**
```
=== LOADING RESOURCES FROM SUPABASE ===
✓ Resources loaded from Supabase: [...]
Total resources: 5
Creating resource cards for 5 resources
```

---

## Helper Functions

### escapeHtml()
**Purpose:** Prevent XSS attacks by escaping HTML characters

**Usage:**
```javascript
escapeHtml(resource.name)  // Converts <script> to &lt;script&gt;
```

---

## Database Schema Reference

### resources table
```
Column      Type              Nullable  Default
─────────────────────────────────────────────────
id          uuid              false     gen_random_uuid()
name        text              false     
description text              true      
file_url    text              false     
created_at  timestamp with tz false     now()
```

---

## Supabase Client Initialization

**Both Files Use:**
```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

**CDN Script (included in both HTML files):**
```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
```

---

## File Upload Process

```
1. User selects file in #resource-file input
2. Form submission triggers uploadResource()
3. ✓ Validate inputs and file size
4. Generate unique filename: crypto.randomUUID() + extension
5. Upload to Supabase Storage:
   await supabase.storage
       .from('resources')
       .upload(filePath, file)
6. Get public URL:
   supabase.storage.from('resources').getPublicUrl(filePath)
7. Insert metadata to database:
   await supabase.from('resources').insert([{...}])
8. ✓ Show success message
9. ✓ Refresh resource list with loadResources()
```

---

## Error Scenarios & Logging

### Successful Upload
```
=== RESOURCE FORM SUBMITTED ===
Form data: {name: "Guide", description: "...", fileName: "guide.pdf"}
Starting file upload to Supabase Storage...
File details: {name: "guide.pdf", size: 1048576, type: "application/pdf"}
Generated unique filename: 550e8400-e29b-41d4-a716-446655440000.pdf
Upload path: 550e8400-e29b-41d4-a716-446655440000.pdf
✓ File uploaded to Supabase Storage: {path: "..."}
✓ Public URL generated: https://....supabase.co/storage/v1/object/public/resources/550e...
✓ Resource metadata saved to database: [{id: "...", name: "Guide", ...}]
✓ Resource uploaded successfully! [User message]
```

### Upload Error Examples
```
// File too large
Form validation failed: File size exceeds limit: 52428800
✗ File size exceeds 50MB limit

// Missing inputs
Form validation failed: name or file missing
✗ Please fill in all fields and select a file

// Network error
❌ Error uploading resource: Network error
✗ Upload failed: Network error
```

---

## Testing Checklist

### Dashboard Upload
- [ ] Form fields display correctly
- [ ] File size validation works (<50MB passes, >50MB fails)
- [ ] File uploads without error
- [ ] Success message appears
- [ ] Resource appears in "📦 Resources Library" section
- [ ] Console shows upload logs

### Resources Page
- [ ] Page loads automatically
- [ ] Resources display as cards
- [ ] Each card shows name, description, download button
- [ ] Download button links to correct file
- [ ] Empty state shows when no resources
- [ ] Console shows load logs

---

## Quick Troubleshooting

| Issue | Check |
|-------|-------|
| Resources not loading | 1. Credentials correct? 2. Network tab shows request? 3. Console errors? |
| Upload fails | 1. File <50MB? 2. Bucket public? 3. Credentials correct? |
| Download button broken | 1. file_url in database? 2. file exists in storage? |
| Empty state always shows | 1. Query returns data? 2. Check database has rows? |
| Console errors | 1. Check full error message 2. Look up error code in Supabase docs |

---

## API Endpoints Used

### Upload File
```javascript
supabase.storage.from('resources').upload(path, file)
```

### Get Public URL
```javascript
supabase.storage.from('resources').getPublicUrl(path)
```

### Insert Record
```javascript
supabase.from('resources').insert([{...}])
```

### Fetch Records
```javascript
supabase.from('resources').select('*').order('created_at', { ascending: false })
```

### Delete Record
```javascript
supabase.from('resources').delete().eq('id', resourceId)
```

---

## Important Notes

- **UUID Format:** 550e8400-e29b-41d4-a716-446655440000
- **Max File Size:** 50 MB (hardcoded in validation)
- **Bucket Name:** Must be `resources` (case-sensitive)
- **Table Name:** Must be `resources` (case-sensitive)
- **Public Access:** Both storage and table must allow public read
- **File Naming:** Randomized with UUID to prevent duplicates
