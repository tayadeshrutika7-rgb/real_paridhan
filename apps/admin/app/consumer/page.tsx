"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "../../lib/supabase";
import {
  Compass,
  Store,
  Tag,
  ShoppingBag,
  MessageSquare,
  Search,
  MapPin,
  Star,
  ArrowRight,
  Sparkles,
  Percent,
  CheckCircle2,
} from "lucide-react";

export default function ConsumerHomePage() {
  const [categories, setCategories] = useState<any[]>([]);
  const [shops, setShops] = useState<any[]>([]);
  const [products, setProducts] = useState<any[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadMarketplace() {
      try {
        const [{ data: catData }, { data: shopData }, { data: prodData }] = await Promise.all([
          supabase.from("categories").select("*"),
          supabase.from("shops").select("*").eq("status", "verified"),
          supabase.from("products").select("*, product_variants(*), shops(name, address)").eq("status", "active").limit(8),
        ]);

        if (catData) setCategories(catData);
        if (shopData) setShops(shopData);
        if (prodData) setProducts(prodData);
      } catch (err) {
        console.warn("Failed to load consumer marketplace:", err);
      } finally {
        setLoading(false);
      }
    }
    loadMarketplace();
  }, []);

  const filteredProducts = products.filter(
    (p) =>
      p.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.description?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div style={{ minHeight: "calc(100vh - 65px)", backgroundColor: "#090d16", paddingBottom: "60px" }}>
      {/* Sub Navigation Bar for Consumer */}
      <div
        style={{
          borderBottom: "1px solid #1e293b",
          backgroundColor: "#0d1322",
          padding: "10px 24px",
          display: "flex",
          alignItems: "center",
          gap: "16px",
          overflowX: "auto",
        }}
      >
        {[
          { label: "Marketplace", href: "/consumer", active: true },
          { label: "Nearby Boutiques", href: "/consumer/shops", active: false },
          { label: "All Products", href: "/consumer/products", active: false },
          { label: "Bargain Deals", href: "/consumer/bargains", active: false },
          { label: "Shopping Bag", href: "/consumer/cart", active: false },
          { label: "My Orders", href: "/consumer/orders", active: false },
        ].map((sub) => (
          <Link
            key={sub.label}
            href={sub.href}
            style={{
              fontSize: "13px",
              fontWeight: sub.active ? "700" : "500",
              color: sub.active ? "#38bdf8" : "#94a3b8",
              textDecoration: "none",
              padding: "4px 8px",
              borderRadius: "6px",
              backgroundColor: sub.active ? "#0284c715" : "transparent",
              whiteSpace: "nowrap",
            }}
          >
            {sub.label}
          </Link>
        ))}
      </div>

      <div style={{ maxWidth: "1280px", margin: "0 auto", padding: "28px 24px" }}>
        {/* Hero Search Banner */}
        <div
          style={{
            background: "linear-gradient(135deg, #1e1b4b 0%, #0f172a 100%)",
            border: "1px solid #1e293b",
            borderRadius: "16px",
            padding: "36px 32px",
            marginBottom: "36px",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            textAlign: "center",
          }}
        >
          <div
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "6px",
              padding: "4px 12px",
              borderRadius: "9999px",
              backgroundColor: "#f43f5e15",
              color: "#f43f5e",
              fontSize: "12px",
              fontWeight: "600",
              marginBottom: "12px",
            }}
          >
            <MapPin size={13} /> Location: Johari Bazaar & Pink City, Jaipur (2.4 km radius)
          </div>
          <h1 style={{ fontSize: "30px", fontWeight: "800", color: "#ffffff", margin: "0 0 8px" }}>
            Discover Authentic Local Fashion
          </h1>
          <p style={{ color: "#94a3b8", fontSize: "14px", maxWidth: "550px", margin: "0 0 24px" }}>
            Boutiques in your neighborhood. Real-time bargaining with floor price validation and same-day bike dispatch.
          </p>

          {/* Search Box */}
          <div
            style={{
              position: "relative",
              width: "100%",
              maxWidth: "580px",
            }}
          >
            <Search size={18} style={{ position: "absolute", left: "16px", top: "14px", color: "#64748b" }} />
            <input
              type="text"
              placeholder="Search handcrafted sarees, royal sherwanis, anarkalis, juttis..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                width: "100%",
                padding: "13px 18px 13px 46px",
                borderRadius: "12px",
                backgroundColor: "#090d16",
                border: "1px solid #334155",
                color: "#f1f5f9",
                fontSize: "14px",
                outline: "none",
                boxShadow: "0 8px 20px rgba(0,0,0,0.3)",
              }}
            />
          </div>
        </div>

        {/* Categories Carousel */}
        <div style={{ marginBottom: "36px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
            <h2 style={{ fontSize: "18px", fontWeight: "700", color: "#ffffff", margin: 0 }}>
              Shop by Category
            </h2>
            <Link href="/consumer/products" style={{ fontSize: "12px", color: "#38bdf8", textDecoration: "none", fontWeight: "600" }}>
              View Catalog &rarr;
            </Link>
          </div>

          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fill, minmax(130px, 1fr))",
              gap: "12px",
            }}
          >
            {[
              { name: "Bridal Lehengas", icon: "👑" },
              { name: "Sarees & Handlooms", icon: "🥻" },
              { name: "Royal Sherwanis", icon: "🧥" },
              { name: "Anarkali Suits", icon: "👗" },
              { name: "Ethnic Footwear", icon: "🥿" },
              { name: "Jewelry & Acc.", icon: "💎" },
            ].map((cat, idx) => (
              <Link
                key={idx}
                href="/consumer/products"
                style={{
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  justifyContent: "center",
                  padding: "16px 12px",
                  borderRadius: "12px",
                  backgroundColor: "#0d1322",
                  border: "1px solid #1e293b",
                  textDecoration: "none",
                  textAlign: "center",
                }}
              >
                <div style={{ fontSize: "28px", marginBottom: "8px" }}>{cat.icon}</div>
                <div style={{ fontSize: "12px", fontWeight: "600", color: "#f1f5f9" }}>{cat.name}</div>
              </Link>
            ))}
          </div>
        </div>

        {/* Nearby Boutiques */}
        <div style={{ marginBottom: "40px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
            <div>
              <h2 style={{ fontSize: "18px", fontWeight: "700", color: "#ffffff", margin: 0 }}>
                Nearby Boutiques (PostGIS Radius)
              </h2>
              <p style={{ color: "#64748b", fontSize: "12px", margin: "2px 0 0" }}>
                Hyperlocal boutiques within delivery range of Johari Bazaar
              </p>
            </div>
            <Link href="/consumer/shops" style={{ fontSize: "12px", color: "#38bdf8", textDecoration: "none", fontWeight: "600" }}>
              Explore All Boutiques &rarr;
            </Link>
          </div>

          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
              gap: "16px",
            }}
          >
            {shops.map((s) => (
              <div
                key={s.id}
                style={{
                  backgroundColor: "#0d1322",
                  border: "1px solid #1e293b",
                  borderRadius: "12px",
                  padding: "18px",
                  display: "flex",
                  flexDirection: "column",
                  justifyContent: "space-between",
                }}
              >
                <div>
                  <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "10px" }}>
                    <div
                      style={{
                        width: "38px",
                        height: "38px",
                        borderRadius: "8px",
                        backgroundColor: "#1e293b",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        fontSize: "18px",
                      }}
                    >
                      🏪
                    </div>
                    <div>
                      <h3 style={{ fontSize: "15px", fontWeight: "700", color: "#fff", margin: 0 }}>
                        {s.name}
                      </h3>
                      <div style={{ display: "flex", alignItems: "center", gap: "4px", fontSize: "11px", color: "#fbbf24" }}>
                        <Star size={11} fill="#fbbf24" />
                        <span>{s.avg_rating || "4.8"} &bull; Verified</span>
                      </div>
                    </div>
                  </div>
                  <p style={{ fontSize: "12px", color: "#94a3b8", lineHeight: "1.5", marginBottom: "12px" }}>
                    {s.description || "Authentic ethnic apparel & boutique collection."}
                  </p>
                  <div style={{ fontSize: "11px", color: "#64748b", display: "flex", alignItems: "center", gap: "4px", marginBottom: "14px" }}>
                    <MapPin size={12} /> {s.address}
                  </div>
                </div>

                <Link
                  href="/consumer/products"
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: "6px",
                    padding: "8px 12px",
                    borderRadius: "6px",
                    backgroundColor: "#1e293b",
                    color: "#f1f5f9",
                    fontSize: "12px",
                    fontWeight: "600",
                    textDecoration: "none",
                  }}
                >
                  <span>View Catalog</span>
                  <ArrowRight size={13} />
                </Link>
              </div>
            ))}
          </div>
        </div>

        {/* Featured Products Catalog */}
        <div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
            <div>
              <h2 style={{ fontSize: "18px", fontWeight: "700", color: "#ffffff", margin: 0 }}>
                Trending Catalog & Bargain Deals
              </h2>
              <p style={{ color: "#64748b", fontSize: "12px", margin: "2px 0 0" }}>
                Directly negotiable with boutique shopkeepers
              </p>
            </div>
            <Link href="/consumer/products" style={{ fontSize: "12px", color: "#38bdf8", textDecoration: "none", fontWeight: "600" }}>
              See All Products &rarr;
            </Link>
          </div>

          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fill, minmax(270px, 1fr))",
              gap: "20px",
            }}
          >
            {filteredProducts.map((p) => {
              const minBargain = Number(p.min_bargain_price) || 0;
              const basePrice = Number(p.base_price) || 0;
              const discountPct = Math.round(((basePrice - minBargain) / basePrice) * 100);

              return (
                <div
                  key={p.id}
                  style={{
                    backgroundColor: "#0d1322",
                    border: "1px solid #1e293b",
                    borderRadius: "14px",
                    overflow: "hidden",
                    display: "flex",
                    flexDirection: "column",
                  }}
                >
                  {/* Image banner */}
                  <div
                    style={{
                      height: "170px",
                      backgroundColor: "#1e293b",
                      position: "relative",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      fontSize: "42px",
                      backgroundImage: p.product_variants?.[0]?.image_urls?.[0]
                        ? `url(${p.product_variants[0].image_urls[0]})`
                        : "none",
                      backgroundSize: "cover",
                      backgroundPosition: "center",
                    }}
                  >
                    {!p.product_variants?.[0]?.image_urls?.[0] && "👗"}

                    {p.bargain_enabled && (
                      <span
                        style={{
                          position: "absolute",
                          top: "10px",
                          right: "10px",
                          backgroundColor: "#f59e0b",
                          color: "#000",
                          fontSize: "11px",
                          fontWeight: "800",
                          padding: "3px 8px",
                          borderRadius: "9999px",
                          display: "flex",
                          alignItems: "center",
                          gap: "4px",
                        }}
                      >
                        <Percent size={12} /> Bargainable (up to {discountPct}% off)
                      </span>
                    )}
                  </div>

                  {/* Body */}
                  <div style={{ padding: "16px", display: "flex", flexDirection: "column", flex: 1, justifyContent: "space-between" }}>
                    <div>
                      <div style={{ fontSize: "11px", color: "#94a3b8", marginBottom: "4px" }}>
                        {p.shops?.name || "Johari Royal Heritage Boutique"}
                      </div>
                      <h3 style={{ fontSize: "15px", fontWeight: "700", color: "#fff", margin: "0 0 6px" }}>
                        {p.title}
                      </h3>
                      <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 12px", lineHeight: "1.4" }}>
                        {p.description || "Premium ethnic wear crafted with traditional heritage patterns."}
                      </p>

                      {/* Pricing */}
                      <div style={{ display: "flex", alignItems: "baseline", gap: "8px", marginBottom: "16px" }}>
                        <span style={{ fontSize: "18px", fontWeight: "800", color: "#f1f5f9" }}>
                          ₹{basePrice.toLocaleString()}
                        </span>
                        {p.bargain_enabled && (
                          <span style={{ fontSize: "12px", color: "#fbbf24", fontWeight: "600" }}>
                            Floor: ₹{minBargain.toLocaleString()}
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Actions */}
                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "8px" }}>
                      <Link
                        href={`/consumer/bargains?productId=${p.id}`}
                        style={{
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          gap: "6px",
                          padding: "8px",
                          borderRadius: "8px",
                          backgroundColor: "#f59e0b1a",
                          border: "1px solid #f59e0b40",
                          color: "#fbbf24",
                          fontSize: "12px",
                          fontWeight: "700",
                          textDecoration: "none",
                        }}
                      >
                        <MessageSquare size={13} />
                        <span>Bargain</span>
                      </Link>

                      <Link
                        href={`/consumer/cart?add=${p.id}&variant=${p.product_variants?.[0]?.id || ''}`}
                        style={{
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          gap: "6px",
                          padding: "8px",
                          borderRadius: "8px",
                          backgroundColor: "#f43f5e",
                          color: "#ffffff",
                          fontSize: "12px",
                          fontWeight: "700",
                          textDecoration: "none",
                        }}
                      >
                        <ShoppingBag size={13} />
                        <span>Add to Bag</span>
                      </Link>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
