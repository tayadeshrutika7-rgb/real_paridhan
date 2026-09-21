import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || "https://faqtswmhgintutwvnkyy.supabase.co";
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

export async function POST(req: Request) {
  try {
    if (!supabaseServiceKey) {
      return NextResponse.json(
        { error: "Server configuration error: SUPABASE_SERVICE_ROLE_KEY is not configured." },
        { status: 500 }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const body = await req.json();
    const { email, password, fullName, role, phone } = body;

    // Validation
    if (!email || !password || !fullName) {
      return NextResponse.json(
        { error: "Email, password, and full name are required." },
        { status: 400 }
      );
    }

    if (password.length < 6) {
      return NextResponse.json(
        { error: "Password must be at least 6 characters long." },
        { status: 400 }
      );
    }

    // Strictly disallow public registration as admin
    const allowedRoles = ["consumer", "seller", "delivery"];
    const targetRole = allowedRoles.includes(role) ? role : "consumer";

    // Create user via Supabase Auth Admin with email_confirm: true
    // This bypasses unconfigured/rate-limited external SMTP servers while firing the handle_new_user trigger
    const { data, error } = await supabaseAdmin.auth.admin.createUser({
      email: email.trim().toLowerCase(),
      password: password,
      email_confirm: true,
      phone: phone || undefined,
      user_metadata: {
        full_name: fullName.trim(),
        role: targetRole,
      },
    });

    if (error) {
      return NextResponse.json(
        { error: error.message || "Failed to create user account" },
        { status: error.status || 400 }
      );
    }

    // Ensure profile is recorded in public.profiles
    if (data.user) {
      await supabaseAdmin.from("profiles").upsert({
        id: data.user.id,
        role: targetRole,
        full_name: fullName.trim(),
        email: email.trim().toLowerCase(),
        phone: phone || null,
        accepted_terms_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
    }

    return NextResponse.json({
      success: true,
      user: {
        id: data.user?.id,
        email: data.user?.email,
        role: targetRole,
      },
    });
  } catch (err: any) {
    return NextResponse.json(
      { error: err.message || "Internal server error during registration" },
      { status: 500 }
    );
  }
}
