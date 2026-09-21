"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "../../../lib/supabase";
import {
  Layers,
  Tag,
  Plus,
  Minus,
  CheckCircle2,
  AlertTriangle,
  RefreshCw,
  Search,
} from "lucide-react";

export default function SellerInventoryPage() {
  const [variants, setVariants] = useState<any[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [saveMsg, setSaveMsg] = useState<string | null>(null);

  async function loadInventory() {
    try {
      const { data, error } = await supabase
        .from("product_variants")
        .select("*, products(title, base_price, status, shops(name))")
        .order("created_at", { ascending: false });

      if (data && !error && data.length > 0) {
        setVariants(data);
      } else {
        setVariants([
          { id: "var-1", size: "Free Size", color: "Royal Crimson & Gold", stock_qty: 8, sku: "JOH-SLK-001", products: { title: "Johari Handcrafted Silk Saree", base_price: 1500 } },
          { id: "var-2", size: "M", color: "Ivory & Marigold", stock_qty: 5, sku: "JOH-ANK-002", products: { title: "Royal Gota Patti Anarkali Suit", base_price: 2400 } },
          { id: "var-3", size: "XL", color: "Emerald & Gold", stock_qty: 3, sku: "JOH-SHR-003", products: { title: "Rajputana Heritage Silk Sherwani", base_price: 5200 } },
          { id: "var-4", size: "42", color: "Mojari Tan Leather", stock_qty: 12, sku: "JOH-JUT-004", products: { title: "Handcrafted Embroidered Juttis", base_price: 850 } },
        ]);
      }
    } catch (err) {
      console.warn("Failed to load inventory:", err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadInventory();
  }, []);

  async function updateStock(varId: string, newStock: number) {
    if (newStock < 0) return;
    setVariants((prev) =>
      prev.map((v) => (v.id === varId ? { ...v, stock_qty: newStock } : v))
    );

    try {
      await supabase.from("product_variants").update({ stock_qty: newStock }).eq("id", varId);
      setSaveMsg("Stock count updated!");
      setTimeout(() => setSaveMsg(null), 2500);
    } catch (err) {
      console.warn("Stock update error:", err);
    }
  }

  const filtered = variants.filter(
    (v) =>
      v.products?.title?.toLowerCase().includes(search.toLowerCase()) ||
      v.color?.toLowerCase().includes(search.toLowerCase()) ||
      v.sku?.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div style={{ minHeight: "calc(100vh - 65px)", backgroundColor: "#090d16", paddingBottom: "60px" }}>
      {/* Sub Navigation Bar */}
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
          { label: "Seller Studio", href: "/seller", active: false },
          { label: "Catalog & Products", href: "/seller/products", active: false },
          { label: "Orders Fulfillment", href: "/seller/orders", active: false },
          { label: "Bargain Inbox", href: "/seller/bargains", active: false },
          { label: "Inventory Oversight", href: "/seller/inventory", active: true },
        ].map((sub) => (
          <Link
            key={sub.label}
            href={sub.href}
            style={{
              fontSize: "13px",
              fontWeight: sub.active ? "700" : "500",
              color: sub.active ? "#fbbf24" : "#94a3b8",
              textDecoration: "none",
              padding: "4px 8px",
              borderRadius: "6px",
              backgroundColor: sub.active ? "#f59e0b15" : "transparent",
              whiteSpace: "nowrap",
            }}
          >
            {sub.label}
          </Link>
        ))}
      </div>

      <div style={{ maxWidth: "1280px", margin: "0 auto", padding: "32px 24px" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "28px", flexWrap: "wrap", gap: "16px" }}>
          <div>
            <h1 style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff", margin: "0 0 6px" }}>
              Inventory & Stock Management
            </h1>
            <p style={{ color: "#94a3b8", fontSize: "14px", margin: 0 }}>
              Adjust realtime physical inventory across all sizes and color variations
            </p>
          </div>

          <div style={{ position: "relative", width: "100%", maxWidth: "320px" }}>
            <Search size={16} style={{ position: "absolute", left: "12px", top: "11px", color: "#64748b" }} />
            <input
              type="text"
              placeholder="Search by SKU, style, or color..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                width: "100%",
                padding: "9px 12px 9px 36px",
                borderRadius: "8px",
                backgroundColor: "#0d1322",
                border: "1px solid #1e293b",
                color: "#f1f5f9",
                fontSize: "13px",
                outline: "none",
              }}
            />
          </div>
        </div>

        {saveMsg && (
          <div
            style={{
              padding: "12px 16px",
              borderRadius: "8px",
              backgroundColor: "#10b9811a",
              border: "1px solid #10b98150",
              color: "#6ee7b7",
              fontSize: "13px",
              marginBottom: "24px",
              display: "flex",
              alignItems: "center",
              gap: "8px",
            }}
          >
            <CheckCircle2 size={16} />
            <span>{saveMsg}</span>
          </div>
        )}

        <div
          style={{
            backgroundColor: "#0d1322",
            border: "1px solid #1e293b",
            borderRadius: "14px",
            overflow: "hidden",
          }}
        >
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "2fr 1fr 1fr 1fr 160px",
              padding: "14px 20px",
              backgroundColor: "#090d16",
              borderBottom: "1px solid #1e293b",
              fontSize: "12px",
              fontWeight: "700",
              color: "#94a3b8",
              textTransform: "uppercase",
              letterSpacing: "0.5px",
            }}
          >
            <div>Product & SKU</div>
            <div>Size & Color</div>
            <div>Base Price</div>
            <div>Stock Status</div>
            <div style={{ textAlign: "right" }}>Adjust Quantity</div>
          </div>

          <div style={{ display: "flex", flexDirection: "column" }}>
            {filtered.map((v) => {
              const isLowStock = v.stock_qty <= 3;

              return (
                <div
                  key={v.id}
                  style={{
                    display: "grid",
                    gridTemplateColumns: "2fr 1fr 1fr 1fr 160px",
                    padding: "16px 20px",
                    alignItems: "center",
                    borderBottom: "1px solid #1e293b",
                    fontSize: "13px",
                  }}
                >
                  <div>
                    <div style={{ fontWeight: "700", color: "#ffffff" }}>
                      {v.products?.title || "Boutique Product"}
                    </div>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>
                      SKU: {v.sku || `SKU-${v.id.slice(0, 6).toUpperCase()}`}
                    </div>
                  </div>

                  <div>
                    <span style={{ color: "#f1f5f9", fontWeight: "600" }}>{v.size}</span>
                    <span style={{ color: "#64748b" }}> &bull; {v.color}</span>
                  </div>

                  <div style={{ fontWeight: "700", color: "#ffffff" }}>
                    ₹{Number(v.products?.base_price || 1500).toLocaleString()}
                  </div>

                  <div>
                    {isLowStock ? (
                      <span
                        style={{
                          display: "inline-flex",
                          alignItems: "center",
                          gap: "4px",
                          fontSize: "11px",
                          fontWeight: "700",
                          padding: "3px 8px",
                          borderRadius: "4px",
                          backgroundColor: "#ef444420",
                          color: "#f87171",
                          border: "1px solid #ef444440",
                        }}
                      >
                        <AlertTriangle size={12} /> Low Stock ({v.stock_qty})
                      </span>
                    ) : (
                      <span
                        style={{
                          fontSize: "11px",
                          fontWeight: "700",
                          padding: "3px 8px",
                          borderRadius: "4px",
                          backgroundColor: "#10b98120",
                          color: "#34d399",
                          border: "1px solid #10b98140",
                        }}
                      >
                        {v.stock_qty} in stock
                      </span>
                    )}
                  </div>

                  {/* Quantity Controls */}
                  <div style={{ display: "flex", alignItems: "center", justifyContent: "flex-end", gap: "8px" }}>
                    <div
                      style={{
                        display: "flex",
                        alignItems: "center",
                        backgroundColor: "#090d16",
                        border: "1px solid #1e293b",
                        borderRadius: "6px",
                        padding: "2px",
                      }}
                    >
                      <button
                        type="button"
                        onClick={() => updateStock(v.id, v.stock_qty - 1)}
                        style={{
                          width: "26px",
                          height: "26px",
                          borderRadius: "4px",
                          backgroundColor: "transparent",
                          border: "none",
                          color: "#94a3b8",
                          cursor: "pointer",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                        }}
                      >
                        <Minus size={13} />
                      </button>

                      <span style={{ padding: "0 8px", fontSize: "13px", fontWeight: "700", color: "#ffffff" }}>
                        {v.stock_qty}
                      </span>

                      <button
                        type="button"
                        onClick={() => updateStock(v.id, v.stock_qty + 1)}
                        style={{
                          width: "26px",
                          height: "26px",
                          borderRadius: "4px",
                          backgroundColor: "transparent",
                          border: "none",
                          color: "#94a3b8",
                          cursor: "pointer",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                        }}
                      >
                        <Plus size={13} />
                      </button>
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
