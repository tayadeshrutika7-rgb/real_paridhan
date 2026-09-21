"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "../lib/authContext";
import { getRoleHomeUrl } from "../lib/RoleGuard";
import { Loader2 } from "lucide-react";

export default function RootPage() {
  const router = useRouter();
  const { user, role, loading } = useAuth();

  useEffect(() => {
    if (!loading) {
      if (!user || !role) {
        router.replace("/auth");
      } else {
        router.replace(getRoleHomeUrl(role));
      }
    }
  }, [user, role, loading, router]);

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
      <Loader2 size={36} className="animate-spin" style={{ color: "#f43f5e" }} />
      <div style={{ fontSize: "14px", fontWeight: "600" }}>
        Loading PARIDHAN Experience...
      </div>
    </div>
  );
}
