// MyDigi public browser client. The publishable key is designed for frontend use;
// database access is protected by Supabase Auth and Row Level Security.
(function () {
  const SUPABASE_URL = "https://rzyiejkkontmxvwfkxhq.supabase.co";
  const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_BHEYr85J7ngD-Nm6kxmPXw_LjwAdngb";
  if (!window.supabase || !window.supabase.createClient) {
    console.error("Supabase JS library did not load.");
    return;
  }
  window.myDigiSupabase = window.supabase.createClient(
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY
  );
})();