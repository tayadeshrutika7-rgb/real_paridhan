"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth, UserRole } from "../../lib/authContext";
import { getRoleHomeUrl } from "../../lib/RoleGuard";
import { parseAuthError } from "../../lib/authErrorParser";
import {
  Lock,
  Mail,
  User,
  ShieldCheck,
  Store,
  Truck,
  ShoppingBag,
  ArrowRight,
  Sparkles,
  AlertCircle,
  CheckCircle2,
  Loader2,
  Check,
} from "lucide-react";

export default function AuthPage() {
  const router = useRouter();
  const { signIn, signUp, user, role, loading } = useAuth();

  const [mode, setMode] = useState<"login" | "signup">("login");
  
  // Form fields
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [selectedRole, setSelectedRole] = useState<"consumer" | "seller" | "delivery">("consumer");
  
  // Validation state
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // If already authenticated, redirect to role home
  useEffect(() => {
    if (!loading && user && role) {
      router.replace(getRoleHomeUrl(role));
    }
  }, [user, role, loading, router]);

  function validateForm(): boolean {
    const errors: Record<string, string> = {};
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!email.trim()) {
      errors.email = "Email address is required.";
    } else if (!emailRegex.test(email.trim())) {
      errors.email = "Please enter a valid email address (e.g. name@domain.com).";
    }

    if (!password) {
      errors.password = "Password is required.";
    } else if (password.length < 6) {
      errors.password = "Password must be at least 6 characters long.";
    }

    if (mode === "signup") {
      if (!fullName.trim()) {
        errors.fullName = "Full name is required.";
      } else if (fullName.trim().length < 2) {
        errors.fullName = "Full name must be at least 2 characters.";
      }

      if (password !== confirmPassword) {
        errors.confirmPassword = "Passwords do not match.";
      }
    }

    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  }

  async function handleAuth(e: React.FormEvent) {
    e.preventDefault();
    setErrorMsg(null);
    setSuccessMsg(null);

    if (!validateForm()) {
      return;
    }

    setSubmitting(true);

    try {
      if (mode === "login") {
        const { error, role: detectedRole } = await signIn(email.trim(), password);
        if (error) {
          const friendlyMessage = parseAuthError(error);
          setErrorMsg(friendlyMessage);
          setSubmitting(false);
        } else {
          const targetUrl = getRoleHomeUrl(detectedRole || "consumer");
          setSuccessMsg(`Signed in successfully as ${detectedRole?.toUpperCase()}! Redirecting...`);
          setTimeout(() => {
            router.replace(targetUrl);
          }, 600);
        }
      } else {
        // Enforce public signup cannot register as admin
        const safeRole: UserRole = selectedRole === "seller" ? "seller" : selectedRole === "delivery" ? "delivery" : "consumer";
        const { error, role: createdRole } = await signUp(email.trim(), password, fullName.trim(), safeRole);
        
        if (error) {
          const friendlyMessage = parseAuthError(error);
          setErrorMsg(friendlyMessage);
          setSubmitting(false);
        } else {
          const targetUrl = getRoleHomeUrl(createdRole || safeRole);
          setSuccessMsg(`Account registered successfully as ${safeRole.toUpperCase()}! Redirecting to your workspace...`);
          setTimeout(() => {
            router.replace(targetUrl);
          }, 800);
        }
      }
    } catch (err: any) {
      const friendlyMessage = parseAuthError(err);
      setErrorMsg(friendlyMessage);
      setSubmitting(false);
    }
  }

  function prefillCredentials(testEmail: string, testPass: string) {
    setMode("login");
    setEmail(testEmail);
    setPassword(testPass);
    setFieldErrors({});
    setErrorMsg(null);
  }

  if (loading) {
    return (
      <div
        style={{
          minHeight: "100vh",
          backgroundColor: "#090d16",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: "16px",
          color: "#94a3b8",
        }}
      >
        <Loader2 size={36} className="animate-spin" style={{ color: "#38bdf8" }} />
        <div style={{ fontSize: "14px", fontWeight: "600" }}>
          Verifying security session...
        </div>
      </div>
    );
  }

  return (
    <div
      style={{
        minHeight: "100vh",
        backgroundColor: "#090d16",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: "32px 16px",
      }}
    >
      <div
        style={{
          width: "100%",
          maxWidth: "520px",
          backgroundColor: "#0d1322",
          border: "1px solid #1e293b",
          borderRadius: "16px",
          padding: "36px 32px",
          boxShadow: "0 20px 40px rgba(0,0,0,0.6)",
        }}
      >
        {/* Brand Header */}
        <div style={{ textAlign: "center", marginBottom: "26px" }}>
          <div
            style={{
              width: "48px",
              height: "48px",
              borderRadius: "12px",
              background: "linear-gradient(135deg, #f43f5e 0%, #e11d48 100%)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: "24px",
              margin: "0 auto 14px",
              boxShadow: "0 0 20px rgba(244,63,94,0.35)",
            }}
          >
            👗
          </div>
          <h1 style={{ fontSize: "22px", fontWeight: "800", color: "#ffffff", margin: "0 0 4px" }}>
            PARIDHAN Authentication
          </h1>
          <p style={{ fontSize: "13px", color: "#94a3b8", margin: 0 }}>
            {mode === "login"
              ? "Sign in to access your authorized role portal"
              : "Register as a Consumer, Boutique Seller, or Delivery Partner"}
          </p>
        </div>

        {/* Tab Switcher */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            backgroundColor: "#090d16",
            padding: "4px",
            borderRadius: "10px",
            border: "1px solid #1e293b",
            marginBottom: "20px",
          }}
        >
          <button
            type="button"
            onClick={() => {
              setMode("login");
              setFieldErrors({});
              setErrorMsg(null);
            }}
            style={{
              padding: "10px",
              borderRadius: "8px",
              border: "none",
              backgroundColor: mode === "login" ? "#2563eb" : "transparent",
              color: mode === "login" ? "#ffffff" : "#94a3b8",
              fontSize: "13px",
              fontWeight: mode === "login" ? "700" : "500",
              cursor: "pointer",
            }}
          >
            Sign In
          </button>
          <button
            type="button"
            onClick={() => {
              setMode("signup");
              setFieldErrors({});
              setErrorMsg(null);
            }}
            style={{
              padding: "10px",
              borderRadius: "8px",
              border: "none",
              backgroundColor: mode === "signup" ? "#2563eb" : "transparent",
              color: mode === "signup" ? "#ffffff" : "#94a3b8",
              fontSize: "13px",
              fontWeight: mode === "signup" ? "700" : "500",
              cursor: "pointer",
            }}
          >
            Register
          </button>
        </div>

        {/* Global Error Alert */}
        {errorMsg && (
          <div
            style={{
              display: "flex",
              alignItems: "flex-start",
              gap: "10px",
              padding: "12px 14px",
              borderRadius: "8px",
              backgroundColor: "#ef44441a",
              border: "1px solid #ef444450",
              color: "#fca5a5",
              fontSize: "13px",
              marginBottom: "18px",
              lineHeight: "1.4",
            }}
          >
            <AlertCircle size={17} style={{ flexShrink: 0, marginTop: "2px" }} />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* Global Success Alert */}
        {successMsg && (
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "8px",
              padding: "12px 14px",
              borderRadius: "8px",
              backgroundColor: "#10b9811a",
              border: "1px solid #10b98150",
              color: "#6ee7b7",
              fontSize: "13px",
              marginBottom: "18px",
              fontWeight: "600",
            }}
          >
            <CheckCircle2 size={17} />
            <span>{successMsg}</span>
          </div>
        )}

        {/* Auth Form */}
        <form onSubmit={handleAuth} noValidate style={{ display: "flex", flexDirection: "column", gap: "14px" }}>
          {mode === "signup" && (
            <>
              {/* Full Name */}
              <div>
                <label style={{ display: "block", fontSize: "12px", fontWeight: "600", color: "#cbd5e1", marginBottom: "4px" }}>
                  Full Name
                </label>
                <div style={{ position: "relative" }}>
                  <User size={16} style={{ position: "absolute", left: "12px", top: "12px", color: "#64748b" }} />
                  <input
                    type="text"
                    value={fullName}
                    onChange={(e) => {
                      setFullName(e.target.value);
                      if (fieldErrors.fullName) setFieldErrors(prev => ({ ...prev, fullName: "" }));
                    }}
                    placeholder="e.g. Priya Sharma"
                    style={{
                      width: "100%",
                      padding: "10px 12px 10px 38px",
                      borderRadius: "8px",
                      backgroundColor: "#090d16",
                      border: `1px solid ${fieldErrors.fullName ? "#ef4444" : "#1e293b"}`,
                      color: "#f1f5f9",
                      fontSize: "13px",
                      outline: "none",
                    }}
                  />
                </div>
                {fieldErrors.fullName && (
                  <div style={{ color: "#f87171", fontSize: "11px", marginTop: "4px" }}>
                    {fieldErrors.fullName}
                  </div>
                )}
              </div>

              {/* Public Registration Roles (Consumer, Seller, Delivery ONLY — Admin is NEVER public) */}
              <div>
                <label style={{ display: "block", fontSize: "12px", fontWeight: "600", color: "#cbd5e1", marginBottom: "4px" }}>
                  Select Registration Role
                </label>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "8px" }}>
                  {[
                    { id: "consumer", label: "🛍️ Buyer", desc: "Consumer" },
                    { id: "seller", label: "🏪 Seller", desc: "Boutique" },
                    { id: "delivery", label: "🛵 Rider", desc: "Delivery" },
                  ].map((r) => (
                    <button
                      key={r.id}
                      type="button"
                      onClick={() => setSelectedRole(r.id as any)}
                      style={{
                        padding: "10px 6px",
                        borderRadius: "8px",
                        border: `1px solid ${selectedRole === r.id ? "#38bdf8" : "#1e293b"}`,
                        backgroundColor: selectedRole === r.id ? "#0284c715" : "#090d16",
                        textAlign: "center",
                        cursor: "pointer",
                      }}
                    >
                      <div style={{ fontSize: "12px", fontWeight: "700", color: selectedRole === r.id ? "#38bdf8" : "#f1f5f9" }}>
                        {r.label}
                      </div>
                      <div style={{ fontSize: "10px", color: "#64748b" }}>{r.desc}</div>
                    </button>
                  ))}
                </div>
              </div>
            </>
          )}

          {/* Email Address */}
          <div>
            <label style={{ display: "block", fontSize: "12px", fontWeight: "600", color: "#cbd5e1", marginBottom: "4px" }}>
              Email Address
            </label>
            <div style={{ position: "relative" }}>
              <Mail size={16} style={{ position: "absolute", left: "12px", top: "12px", color: "#64748b" }} />
              <input
                type="email"
                value={email}
                onChange={(e) => {
                  setEmail(e.target.value);
                  if (fieldErrors.email) setFieldErrors(prev => ({ ...prev, email: "" }));
                }}
                placeholder="name@domain.com"
                style={{
                  width: "100%",
                  padding: "10px 12px 10px 38px",
                  borderRadius: "8px",
                  backgroundColor: "#090d16",
                  border: `1px solid ${fieldErrors.email ? "#ef4444" : "#1e293b"}`,
                  color: "#f1f5f9",
                  fontSize: "13px",
                  outline: "none",
                }}
              />
            </div>
            {fieldErrors.email && (
              <div style={{ color: "#f87171", fontSize: "11px", marginTop: "4px" }}>
                {fieldErrors.email}
              </div>
            )}
          </div>

          {/* Password */}
          <div>
            <label style={{ display: "block", fontSize: "12px", fontWeight: "600", color: "#cbd5e1", marginBottom: "4px" }}>
              Password
            </label>
            <div style={{ position: "relative" }}>
              <Lock size={16} style={{ position: "absolute", left: "12px", top: "12px", color: "#64748b" }} />
              <input
                type="password"
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value);
                  if (fieldErrors.password) setFieldErrors(prev => ({ ...prev, password: "" }));
                }}
                placeholder="••••••••"
                style={{
                  width: "100%",
                  padding: "10px 12px 10px 38px",
                  borderRadius: "8px",
                  backgroundColor: "#090d16",
                  border: `1px solid ${fieldErrors.password ? "#ef4444" : "#1e293b"}`,
                  color: "#f1f5f9",
                  fontSize: "13px",
                  outline: "none",
                }}
              />
            </div>
            {fieldErrors.password && (
              <div style={{ color: "#f87171", fontSize: "11px", marginTop: "4px" }}>
                {fieldErrors.password}
              </div>
            )}
          </div>

          {/* Confirm Password (Signup only) */}
          {mode === "signup" && (
            <div>
              <label style={{ display: "block", fontSize: "12px", fontWeight: "600", color: "#cbd5e1", marginBottom: "4px" }}>
                Confirm Password
              </label>
              <div style={{ position: "relative" }}>
                <Lock size={16} style={{ position: "absolute", left: "12px", top: "12px", color: "#64748b" }} />
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => {
                    setConfirmPassword(e.target.value);
                    if (fieldErrors.confirmPassword) setFieldErrors(prev => ({ ...prev, confirmPassword: "" }));
                  }}
                  placeholder="••••••••"
                  style={{
                    width: "100%",
                    padding: "10px 12px 10px 38px",
                    borderRadius: "8px",
                    backgroundColor: "#090d16",
                    border: `1px solid ${fieldErrors.confirmPassword ? "#ef4444" : "#1e293b"}`,
                    color: "#f1f5f9",
                    fontSize: "13px",
                    outline: "none",
                  }}
                />
              </div>
              {fieldErrors.confirmPassword && (
                <div style={{ color: "#f87171", fontSize: "11px", marginTop: "4px" }}>
                  {fieldErrors.confirmPassword}
                </div>
              )}
            </div>
          )}

          {/* Submit Button */}
          <button
            type="submit"
            disabled={submitting}
            style={{
              marginTop: "6px",
              padding: "12px",
              borderRadius: "8px",
              border: "none",
              backgroundColor: "#f43f5e",
              color: "#ffffff",
              fontSize: "14px",
              fontWeight: "700",
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: "8px",
            }}
          >
            {submitting ? (
              <>
                <Loader2 size={16} className="animate-spin" />
                <span>Authenticating with Supabase...</span>
              </>
            ) : (
              <>
                <span>{mode === "login" ? "Sign In to Workspace" : "Create Account"}</span>
                <ArrowRight size={16} />
              </>
            )}
          </button>
        </form>

        {/* Development & Verification Test Credentials Helpers */}
        <div style={{ marginTop: "24px", borderTop: "1px solid #1e293b", paddingTop: "16px" }}>
          <div
            style={{
              fontSize: "11px",
              fontWeight: "700",
              color: "#64748b",
              textTransform: "uppercase",
              letterSpacing: "0.5px",
              marginBottom: "10px",
              display: "flex",
              alignItems: "center",
              gap: "6px",
            }}
          >
            <Sparkles size={12} /> Test Credentials (Pre-fills Sign In)
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "8px" }}>
            {[
              { label: "🛍️ Buyer (Consumer)", email: "buyer1@gm.com", pass: "buyer1@gm.com" },
              { label: "🏪 Seller (Johari)", email: "seller3@gm.com", pass: "seller3@gm.com" },
              { label: "🛵 Rider (Delivery)", email: "delivery1@gm.com", pass: "delivery1@gm.com" },
              { label: "👑 Super Admin (Admin)", email: "admin@paridhan.com", pass: "password123" },
            ].map((acc) => (
              <button
                key={acc.email}
                type="button"
                onClick={() => prefillCredentials(acc.email, acc.pass)}
                style={{
                  padding: "8px 10px",
                  borderRadius: "8px",
                  backgroundColor: "#090d16",
                  border: "1px solid #1e293b",
                  textAlign: "left",
                  cursor: "pointer",
                }}
              >
                <div style={{ fontSize: "11px", fontWeight: "700", color: "#f1f5f9" }}>
                  {acc.label}
                </div>
                <div style={{ fontSize: "10px", color: "#64748b" }}>{acc.email}</div>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
