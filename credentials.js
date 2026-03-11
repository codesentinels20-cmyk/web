/* ============================================
   SUPABASE CREDENTIALS & CLIENT INITIALIZATION
   ============================================ */

const SUPABASE_URL = 'https://fleqkgloxgfgpcugmvza.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZsZXFrZ2xveGdmZ3BjdWdtdnphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4NzAyMTMsImV4cCI6MjA4ODQ0NjIxM30.jBYtHQT1tsGFkYOH29PRl0nZj65G4_m4CARdZ1ajLsQ';

// Initialize Supabase client globally (wait for Supabase library to load)
function initializeSupabase() {
    if (window.supabase && !window.supabaseInstance) {
        window.supabaseInstance = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        console.log('✓ Supabase initialized');
        return window.supabaseInstance;
    }
    return window.supabaseInstance || null;
}

// Make it globally accessible as 'supabase'
if (typeof supabase === 'undefined') {
    var supabase = null;
}

// Initialize when script loads
if (document.readyState === 'loading') {
    // Document is still loading
    document.addEventListener('DOMContentLoaded', function() {
        supabase = initializeSupabase();
    });
} else {
    // Document is already loaded
    supabase = initializeSupabase();
}

// Also expose via window for safe access
window.getSupabase = function() {
    if (!window.supabaseInstance && window.supabase) {
        window.supabaseInstance = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    }
    return window.supabaseInstance;
};

