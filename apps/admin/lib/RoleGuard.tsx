"use client";

import React, { useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
import { useAuth, UserRole } from "./authContext";
import { ShieldAlert, Loader2 } from "lucide-react";

interface RoleGuardProps {
  allowedRole: UserRole | UserRole[];
  children: React.ReactNode;
}

export function getRoleHomeUrl(role: UserRole | null): string {
  switch (role) {
    case "consumer":
      return "/consumer";
    case "seller":
      return "/seller";
    case "delivery":
      return "/delivery";
    case "admin":
      return "/admin";
    default:
      return "/auth";
  }
}

export default function RoleGuard({ allowedRole, children }: RoleGuardProps) {
  const router = useRouter();
  const pathname = usePathname();
  const { user, role, loading } = useAuth();

  const allowedRoles = Array.isArray(allowedRole) ? allowedRole : [allowedRole];
  const isAuthorized = role !== null && allowedRoles.includes(role);

  useEffect(() => {
    if (!loading) {
      if (!user || !role) {
        // Unauthenticated -> redirect to /auth
        router.replace("/auth");
      } else if (!isAuthorized) {
        // Logged in with wrong role -> redirect to own role's home
        const targetHome = getRoleHomeUrl(role);
        router.replace(targetHome);
      }
    }
  }, [user, role, loading, isAuthorized, router]);

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
          Verifying security credentials & authorization...
        </div>
      </div>
    );
  }

  if (!user || !role) {
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
          color: "#f43f5e",
        }}
      >
        <ShieldAlert size={36} />
        <div style={{ fontSize: "14px", fontWeight: "600" }}>
          Authentication required. Redirecting to login...
        </div>
      </div>
    );
  }

  if (!isAuthorized) {
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
          color: "#fbbf24",
        }}
      >
        <ShieldAlert size={36} />
        <div style={{ fontSize: "15px", fontWeight: "700", color: "#ffffff" }}>
          Unauthorized Access Attempt
        </div>
        <div style={{ fontSize: "13px", color: "#94a3b8" }}>
          Your role ({role}) is not authorized for this section. Redirecting to your portal...
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
