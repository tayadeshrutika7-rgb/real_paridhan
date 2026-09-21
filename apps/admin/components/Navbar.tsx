"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useAuth, UserRole } from "../lib/authContext";
import { supabase } from "../lib/supabase";
import {
  ShoppingBag,
  Store,
  Truck,
  ShieldCheck,
  User,
  LogOut,
  Sparkles,
  MessageSquare,
  Compass,
  Tag,
  Layers,
  Package,
} from "lucide-react";

export default function Navbar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, profile, role, signOut, loading } = useAuth();
  const [cartCount, setCartCount] = useState(0);
  const [bargainCount, setBargainCount] = useState(0);

  useEffect(() => {
    if (!user || !role) return;

    async function loadCounters() {
      try {
        if (role === "consumer") {
          const [{ count: cCount }, { count: bCount }] = await Promise.all([
            supabase.from("cart_items").select("*", { count: "exact", head: true }),
            supabase.from("bargains").select("*", { count: "exact", head: true }).eq("status", "open"),
          ]);
          setCartCount(cCount || 0);
          setBargainCount(bCount || 0);
        } else if (role === "seller") {
          const { count: bCount } = await supabase
            .from("bargains")
            .select("*", { count: "exact", head: true })
            .eq("status", "open");
          setBargainCount(bCount || 0);
        }
      } catch (err) {
        // Silent catch
      }
    }
    loadCounters();
  }, [pathname, user, role]);

  // If loading or unauthenticated or on /auth or /, do not show app navbar
  if (loading || !user || !role || pathname === "/auth" || pathname === "/") {
    return null;
  }

  // 1. Consumer Navigation Definition
  const consumerLinks = [
    { label: "Marketplace", href: "/consumer", icon: <Compass size={15} /> },
    { label: "Nearby Boutiques", href: "/consumer/shops", icon: <Store size={15} /> },
    { label: "Products Catalog", href: "/consumer/products", icon: <Tag size={15} /> },
    { label: "Bargain Deals", href: "/consumer/bargains", icon: <MessageSquare size={15} /> },
    { label: "Shopping Bag", href: "/consumer/cart", icon: <ShoppingBag size={15} /> },
    { label: "My Orders", href: "/consumer/orders", icon: <Package size={15} /> },
  ];

  // 2. Seller Navigation Definition
  const sellerLinks = [
    { label: "Seller Studio", href: "/seller", icon: <Store size={15} /> },
    { label: "Catalog & Products", href: "/seller/products", icon: <Tag size={15} /> },
    { label: "Inventory Oversight", href: "/seller/inventory", icon: <Layers size={15} /> },
    { label: "Order Fulfillment", href: "/seller/orders", icon: <Package size={15} /> },
    { label: "Bargain Inbox", href: "/seller/bargains", icon: <MessageSquare size={15} /> },
  ];

  // 3. Delivery Navigation Definition
  const deliveryLinks = [
    { label: "Delivery Radar", href: "/delivery", icon: <Truck size={15} /> },
    { label: "Assigned Trips & OTPs", href: "/delivery/orders", icon: <Package size={15} /> },
    { label: "Rider Profile", href: "/delivery/profile", icon: <User size={15} /> },
  ];

  // 4. Admin Navigation Definition
  const adminLinks = [
    { label: "Admin Console", href: "/admin", icon: <ShieldCheck size={15} /> },
  ];

  let currentNavLinks = consumerLinks;
  let portalTitle = "Consumer Marketplace";
  let portalBadgeColor = "#38bdf8";

  if (role === "seller") {
    currentNavLinks = sellerLinks;
    portalTitle = "Seller Studio";
    portalBadgeColor = "#fbbf24";
  } else if (role === "delivery") {
    currentNavLinks = deliveryLinks;
    portalTitle = "Delivery Radar";
    portalBadgeColor = "#34d399";
  } else if (role === "admin") {
    currentNavLinks = adminLinks;
    portalTitle = "Admin Console";
    portalBadgeColor = "#f43f5e";
  }

  async function handleLogout() {
    await signOut();
    router.replace("/auth");
  }

  return (
    <header
      style={{
        position: "sticky",
        top: 0,
        zIndex: 1000,
        backgroundColor: "#090d16f2",
        backdropFilter: "blur(12px)",
        borderBottom: "1px solid #1e293b",
      }}
    >
      <div
        style={{
          maxWidth: "1400px",
          margin: "0 auto",
          padding: "12px 24px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: "16px",
          flexWrap: "wrap",
        }}
      >
        {/* Role-Specific Brand Header */}
        <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
          <div
            style={{
              width: "36px",
              height: "36px",
              borderRadius: "10px",
              background: "linear-gradient(135deg, #f43f5e 0%, #e11d48 100%)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: "18px",
              boxShadow: "0 0 15px rgba(244,63,94,0.3)",
            }}
          >
            👗
          </div>
          <div>
            <div
              style={{
                fontSize: "16px",
                fontWeight: "800",
                letterSpacing: "-0.02em",
                color: "#ffffff",
                display: "flex",
                alignItems: "center",
                gap: "8px",
              }}
            >
              PARIDHAN
              <span
                style={{
                  fontSize: "10px",
                  fontWeight: "700",
                  textTransform: "uppercase",
                  padding: "2px 8px",
                  borderRadius: "4px",
                  backgroundColor: `${portalBadgeColor}20`,
                  color: portalBadgeColor,
                  border: `1px solid ${portalBadgeColor}40`,
                  letterSpacing: "0.5px",
                }}
              >
                {portalTitle}
              </span>
            </div>
            <div style={{ fontSize: "11px", color: "#94a3b8" }}>
              Wear Local &bull; Support Local
            </div>
          </div>
        </div>

        {/* Dedicated Role-Only Navigation Tabs */}
        <nav
          style={{
            display: "flex",
            alignItems: "center",
            gap: "4px",
            backgroundColor: "#0d1322",
            padding: "4px",
            borderRadius: "10px",
            border: "1px solid #1e293b",
          }}
        >
          {currentNavLinks.map((item) => {
            const isActive =
              item.href === "/"
                ? pathname === "/"
                : pathname === item.href || (item.href !== "/consumer" && item.href !== "/seller" && item.href !== "/delivery" && item.href !== "/admin" && pathname.startsWith(item.href));

            return (
              <Link
                key={item.href}
                href={item.href}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "6px",
                  padding: "6px 12px",
                  borderRadius: "7px",
                  fontSize: "12px",
                  fontWeight: isActive ? "700" : "500",
                  color: isActive ? "#ffffff" : "#94a3b8",
                  backgroundColor: isActive ? "#2563eb" : "transparent",
                  textDecoration: "none",
                  transition: "all 0.15s ease",
                  whiteSpace: "nowrap",
                }}
              >
                {item.icon}
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>

        {/* Right Action Profile & Logout */}
        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
          {/* Consumer Action Counters */}
          {role === "consumer" && (
            <>
              <Link
                href="/consumer/bargains"
                style={{
                  position: "relative",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  width: "36px",
                  height: "36px",
                  borderRadius: "8px",
                  backgroundColor: "#131b2e",
                  border: "1px solid #1e293b",
                  color: "#fbbf24",
                  textDecoration: "none",
                }}
                title="Bargain Deals"
              >
                <MessageSquare size={16} />
                {bargainCount > 0 && (
                  <span
                    style={{
                      position: "absolute",
                      top: "-4px",
                      right: "-4px",
                      backgroundColor: "#f59e0b",
                      color: "#000",
                      fontSize: "10px",
                      fontWeight: "800",
                      borderRadius: "9999px",
                      minWidth: "16px",
                      height: "16px",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      padding: "0 4px",
                    }}
                  >
                    {bargainCount}
                  </span>
                )}
              </Link>

              <Link
                href="/consumer/cart"
                style={{
                  position: "relative",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  width: "36px",
                  height: "36px",
                  borderRadius: "8px",
                  backgroundColor: "#131b2e",
                  border: "1px solid #1e293b",
                  color: "#f43f5e",
                  textDecoration: "none",
                }}
                title="Shopping Bag"
              >
                <ShoppingBag size={16} />
                {cartCount > 0 && (
                  <span
                    style={{
                      position: "absolute",
                      top: "-4px",
                      right: "-4px",
                      backgroundColor: "#f43f5e",
                      color: "#ffffff",
                      fontSize: "10px",
                      fontWeight: "800",
                      borderRadius: "9999px",
                      minWidth: "16px",
                      height: "16px",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      padding: "0 4px",
                    }}
                  >
                    {cartCount}
                  </span>
                )}
              </Link>
            </>
          )}

          {/* User Profile Info */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "8px",
              padding: "6px 12px",
              borderRadius: "8px",
              backgroundColor: "#0d1322",
              border: "1px solid #1e293b",
              fontSize: "12px",
            }}
          >
            <User size={14} style={{ color: portalBadgeColor }} />
            <div>
              <div style={{ fontWeight: "700", color: "#f1f5f9", lineHeight: "1.2" }}>
                {profile?.full_name || user.email?.split("@")[0] || "Authenticated"}
              </div>
              <div style={{ fontSize: "10px", color: "#64748b", textTransform: "uppercase" }}>
                {role}
              </div>
            </div>
          </div>

          {/* Logout Button */}
          <button
            onClick={handleLogout}
            style={{
              display: "flex",
              alignItems: "center",
              gap: "6px",
              padding: "8px 12px",
              borderRadius: "8px",
              backgroundColor: "#ef444415",
              border: "1px solid #ef444435",
              color: "#f87171",
              fontSize: "12px",
              fontWeight: "600",
              cursor: "pointer",
            }}
            title="Sign Out"
          >
            <LogOut size={14} />
            <span>Sign Out</span>
          </button>
        </div>
      </div>
    </header>
  );
}
