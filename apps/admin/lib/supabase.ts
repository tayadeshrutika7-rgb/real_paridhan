import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || "https://faqtswmhgintutwvnkyy.supabase.co";
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZhcXRzd21oZ2ludHV0d3Zua3l5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0NjI0NTMsImV4cCI6MjEwMjAzODQ1M30.nr2puO_hmsJoqyEBVefABmNMqv6ENBb6QDUPF0BlNn8";

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
