/**
 * PARIDHAN - Supabase Auth Error Parser & Formatter
 * Formats raw Supabase/PostgreSQL errors into clear, user-friendly messages.
 * Never outputs "{}", "[object Object]", "undefined", or raw unhandled codes.
 */

export function parseAuthError(error: any): string {
  if (!error) return "An unexpected error occurred. Please try again.";

  // Safe developer diagnostic logging in console
  if (typeof window !== "undefined") {
    console.debug("[PARIDHAN Auth Diagnostic]:", error);
  }

  // Extract raw message string
  let rawMsg = "";
  if (typeof error === "string") {
    rawMsg = error;
  } else if (error.message && typeof error.message === "string") {
    rawMsg = error.message;
  } else if (error.msg && typeof error.msg === "string") {
    rawMsg = error.msg;
  } else if (error.error_description && typeof error.error_description === "string") {
    rawMsg = error.error_description;
  } else {
    try {
      rawMsg = JSON.stringify(error);
    } catch {
      rawMsg = String(error);
    }
  }

  // Handle empty or stringified empty objects
  if (!rawMsg || rawMsg === "{}" || rawMsg === "[]" || rawMsg === "[object Object]") {
    return "Registration service temporarily unavailable. Please verify your details and try again.";
  }

  const lower = rawMsg.toLowerCase();

  // 1. Duplicate / Existing User
  if (
    lower.includes("already registered") ||
    lower.includes("already exists") ||
    lower.includes("user already registered") ||
    lower.includes("email_exists") ||
    lower.includes("duplicate key") ||
    lower.includes("unique constraint")
  ) {
    return "An account with this email already exists. Please sign in instead.";
  }

  // 2. Invalid Credentials / Password Mismatch
  if (
    lower.includes("invalid login credentials") ||
    lower.includes("invalid credentials") ||
    lower.includes("wrong password") ||
    lower.includes("invalid_grant")
  ) {
    return "Invalid email or password. Please check your credentials.";
  }

  // 3. Password Requirements
  if (
    lower.includes("password should be at least") ||
    lower.includes("weak password") ||
    lower.includes("password is too short")
  ) {
    return "Password must be at least 6 characters long.";
  }

  // 4. Invalid Email Format
  if (
    lower.includes("valid email") ||
    lower.includes("invalid email") ||
    lower.includes("unable to validate email")
  ) {
    return "Please enter a valid email address.";
  }

  // 5. Database Trigger / GoTrue 500 Error
  if (
    lower.includes("database error saving new user") ||
    lower.includes("database error creating new user") ||
    lower.includes("unexpected_failure") ||
    lower.includes("500")
  ) {
    return "Database auth trigger error on remote server. Please ensure the trigger function is updated in Supabase or sign in with your pre-seeded account.";
  }

  // 6. Rate Limiting
  if (
    lower.includes("rate limit") ||
    lower.includes("too many requests") ||
    lower.includes("over_email_send_rate_limit")
  ) {
    return "Too many attempts. Please wait a moment and try again.";
  }

  // 7. Fallback clean message
  return rawMsg.replace(/^[a-zA-Z_]+:\s*/, "");
}
