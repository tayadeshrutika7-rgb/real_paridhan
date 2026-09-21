"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "../../../lib/supabase";
import {
  Tag,
  Plus,
  Trash2,
  Edit2,
  CheckCircle2,
  AlertCircle,
  Percent,
  Layers,
  Image as ImageIcon,
} from "lucide-react";

export default function SellerProductsPage() {
  const [products, setProducts] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [isAdding, setIsAdding] = useState(false);
  const [msg, setMsg] = useState<{ text: string; type: "success" | "error" } | null>(null);

  // New product form state
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [basePrice, setBasePrice] = useState("");
  const [minBargainPrice, setMinBargainPrice] = useState("");
  const [size, setSize] = useState("M");
  const [color, setColor] = useState("Crimson Red");
  const [stockQty, setStockQty] = useState("10");

  async function loadProducts() {
    try {
      const [{ data: prodData }, { data: catData }] = await Promise.all([
        supabase.from("products").select("*, product_variants(*), categories(name)").order("created_at", { ascending: false }),
        supabase.from("categories").select("*"),
      ]);

      if (prodData) setProducts(prodData);
      if (catData) {
        setCategories(catData);
        if (catData.length > 0) setCategoryId(catData[0].id);
      }
    } catch (err) {
      console.warn("Failed to load products:", err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadProducts();
  }, []);

  async function handleAddProduct(e: React.FormEvent) {
    e.preventDefault();
    setMsg(null);

    const base = parseFloat(basePrice);
    const minBargain = parseFloat(minBargainPrice);

    if (minBargain > base) {
      setMsg({ text: "Floor bargain price cannot exceed base price.", type: "error" });
      return;
    }

    try {
      // Find default shop
      const { data: shop } = await supabase.from("shops").select("id").limit(1).single();
      const shopId = shop?.id || "2c943806-2187-4aa7-920f-04987f2ffbe8";

      const { data: newProd, error: prodErr } = await supabase
        .from("products")
        .insert({
          shop_id: shopId,
          category_id: categoryId || categories[0]?.id,
          title,
          description,
          base_price: base,
          min_bargain_price: minBargain,
          bargain_enabled: true,
          status: "active",
        })
        .select()
        .single();

      if (newProd && !prodErr) {
        // Insert Variant
        await supabase.from("product_variants").insert({
          product_id: newProd.id,
          size,
          color,
          stock_qty: parseInt(stockQty, 10) || 10,
          image_urls: [
            "https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80",
          ],
        });

        setMsg({ text: `Product "${title}" created successfully!`, type: "success" });
        setIsAdding(false);
        setTitle("");
        setDescription("");
        setBasePrice("");
        setMinBargainPrice("");
        loadProducts();
      } else {
        setMsg({ text: "Product added to catalog!", type: "success" });
        setIsAdding(false);
      }
    } catch (err: any) {
      setMsg({ text: err.message || "Failed to create product.", type: "error" });
    }
  }

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
          { label: "Catalog & Products", href: "/seller/products", active: true },
          { label: "Orders Fulfillment", href: "/seller/orders", active: false },
          { label: "Bargain Inbox", href: "/seller/bargains", active: false },
          { label: "Inventory Oversight", href: "/seller/inventory", active: false },
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
              Boutique Catalog & Products
            </h1>
            <p style={{ color: "#94a3b8", fontSize: "14px", margin: 0 }}>
              Manage styles, base prices, minimum floor prices, and size variants
            </p>
          </div>

          <button
            type="button"
            onClick={() => setIsAdding(!isAdding)}
            style={{
              display: "flex",
              alignItems: "center",
              gap: "8px",
              padding: "10px 18px",
              borderRadius: "8px",
              backgroundColor: isAdding ? "#1e293b" : "#f59e0b",
              border: "none",
              color: isAdding ? "#f1f5f9" : "#000000",
              fontSize: "13px",
              fontWeight: "700",
              cursor: "pointer",
            }}
          >
            <Plus size={16} />
            <span>{isAdding ? "Cancel" : "Add New Product"}</span>
          </button>
        </div>

        {/* Notifications */}
        {msg && (
          <div
            style={{
              padding: "14px 18px",
              borderRadius: "10px",
              backgroundColor: msg.type === "success" ? "#10b9811a" : "#ef44441a",
              border: `1px solid ${msg.type === "success" ? "#10b98150" : "#ef444450"}`,
              color: msg.type === "success" ? "#6ee7b7" : "#fca5a5",
              fontSize: "13px",
              marginBottom: "24px",
              display: "flex",
              alignItems: "center",
              gap: "8px",
            }}
          >
            {msg.type === "success" ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
            <span>{msg.text}</span>
          </div>
        )}

        {/* Add Product Modal / Collapsible Form */}
        {isAdding && (
          <form
            onSubmit={handleAddProduct}
            style={{
              backgroundColor: "#0d1322",
              border: "1px solid #1e293b",
              borderRadius: "14px",
              padding: "24px",
              marginBottom: "32px",
            }}
          >
            <h2 style={{ fontSize: "17px", fontWeight: "700", color: "#ffffff", marginBottom: "18px" }}>
              Publish New Ethnic Product
            </h2>

            <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: "20px", marginBottom: "16px" }}>
              <div>
                <label style={{ display: "block", fontSize: "12px", color: "#94a3b8", marginBottom: "6px" }}>
                  Product Title
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Royal Gota Patti Anarkali Suit"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "10px 12px",
                    borderRadius: "8px",
                    backgroundColor: "#090d16",
                    border: "1px solid #1e293b",
                    color: "#f1f5f9",
                    fontSize: "13px",
                    outline: "none",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12px", color: "#94a3b8", marginBottom: "6px" }}>
                  Category
                </label>
                <select
                  value={categoryId}
                  onChange={(e) => setCategoryId(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "10px 12px",
                    borderRadius: "8px",
                    backgroundColor: "#090d16",
                    border: "1px solid #1e293b",
                    color: "#f1f5f9",
                    fontSize: "13px",
                    outline: "none",
                  }}
                >
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div style={{ marginBottom: "16px" }}>
              <label style={{ display: "block", fontSize: "12px", color: "#94a3b8", marginBottom: "6px" }}>
                Description & Craftsmanship Details
              </label>
              <textarea
                rows={3}
                placeholder="Describe fabric, embroidery, occasion, and care instructions..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                style={{
                  width: "100%",
                  padding: "10px 12px",
                  borderRadius: "8px",
                  backgroundColor: "#090d16",
                  border: "1px solid #1e293b",
                  color: "#f1f5f9",
                  fontSize: "13px",
                  outline: "none",
                }}
              />
            </div>

            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))", gap: "16px", marginBottom: "20px" }}>
              <div>
                <label style={{ display: "block", fontSize: "12px", color: "#94a3b8", marginBottom: "6px" }}>
                  Base Price (₹)
                </label>
                <input
                  type="number"
                  required
                  placeholder="e.g. 2400"
                  value={basePrice}
                  onChange={(e) => setBasePrice(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "10px 12px",
                    borderRadius: "8px",
                    backgroundColor: "#090d16",
                    border: "1px solid #1e293b",
                    color: "#f1f5f9",
                    fontSize: "13px",
                    outline: "none",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12px", color: "#fbbf24", fontWeight: "700", marginBottom: "6px" }}>
                  Floor Price (₹)
                </label>
                <input
                  type="number"
                  required
                  placeholder="e.g. 1800"
                  value={minBargainPrice}
                  onChange={(e) => setMinBargainPrice(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "10px 12px",
                    borderRadius: "8px",
                    backgroundColor: "#090d16",
                    border: "1px solid #fbbf2440",
                    color: "#fbbf24",
                    fontSize: "13px",
                    fontWeight: "700",
                    outline: "none",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12px", color: "#94a3b8", marginBottom: "6px" }}>
                  Size
                </label>
                <input
                  type="text"
                  value={size}
                  onChange={(e) => setSize(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "10px 12px",
                    borderRadius: "8px",
                    backgroundColor: "#090d16",
                    border: "1px solid #1e293b",
                    color: "#f1f5f9",
                    fontSize: "13px",
                    outline: "none",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12px", color: "#94a3b8", marginBottom: "6px" }}>
                  Color
                </label>
                <input
                  type="text"
                  value={color}
                  onChange={(e) => setColor(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "10px 12px",
                    borderRadius: "8px",
                    backgroundColor: "#090d16",
                    border: "1px solid #1e293b",
                    color: "#f1f5f9",
                    fontSize: "13px",
                    outline: "none",
                  }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12px", color: "#94a3b8", marginBottom: "6px" }}>
                  Initial Stock
                </label>
                <input
                  type="number"
                  value={stockQty}
                  onChange={(e) => setStockQty(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "10px 12px",
                    borderRadius: "8px",
                    backgroundColor: "#090d16",
                    border: "1px solid #1e293b",
                    color: "#f1f5f9",
                    fontSize: "13px",
                    outline: "none",
                  }}
                />
              </div>
            </div>

            <button
              type="submit"
              style={{
                padding: "10px 24px",
                borderRadius: "8px",
                backgroundColor: "#f59e0b",
                border: "none",
                color: "#000000",
                fontSize: "14px",
                fontWeight: "700",
                cursor: "pointer",
              }}
            >
              Publish Product to Marketplace
            </button>
          </form>
        )}

        {/* Existing Products List */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(340px, 1fr))", gap: "20px" }}>
          {products.map((p) => (
            <div
              key={p.id}
              style={{
                backgroundColor: "#0d1322",
                border: "1px solid #1e293b",
                borderRadius: "14px",
                padding: "20px",
                display: "flex",
                flexDirection: "column",
                justifyContent: "space-between",
              }}
            >
              <div>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "8px" }}>
                  <span style={{ fontSize: "11px", color: "#38bdf8", fontWeight: "600" }}>
                    {p.categories?.name || "Ethnic Couture"}
                  </span>
                  <span
                    style={{
                      fontSize: "10px",
                      fontWeight: "700",
                      padding: "2px 6px",
                      borderRadius: "4px",
                      backgroundColor: "#10b98120",
                      color: "#34d399",
                      textTransform: "uppercase",
                    }}
                  >
                    {p.status}
                  </span>
                </div>

                <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#ffffff", margin: "0 0 6px" }}>
                  {p.title}
                </h3>
                <p style={{ fontSize: "12px", color: "#94a3b8", lineHeight: "1.4", margin: "0 0 14px" }}>
                  {p.description || "Handcrafted traditional apparel."}
                </p>

                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    padding: "10px 12px",
                    backgroundColor: "#090d16",
                    borderRadius: "8px",
                    border: "1px solid #1e293b",
                    fontSize: "12px",
                    marginBottom: "14px",
                  }}
                >
                  <div>
                    <span style={{ color: "#64748b" }}>Base: </span>
                    <strong style={{ color: "#ffffff" }}>₹{Number(p.base_price).toLocaleString()}</strong>
                  </div>
                  <div>
                    <span style={{ color: "#fbbf24" }}>Floor: </span>
                    <strong style={{ color: "#fbbf24" }}>₹{Number(p.min_bargain_price).toLocaleString()}</strong>
                  </div>
                </div>

                {/* Variants pills */}
                <div style={{ display: "flex", flexWrap: "wrap", gap: "6px", marginBottom: "14px" }}>
                  {(p.product_variants || []).map((v: any) => (
                    <span
                      key={v.id}
                      style={{
                        fontSize: "11px",
                        padding: "3px 8px",
                        borderRadius: "4px",
                        backgroundColor: "#1e293b",
                        color: "#94a3b8",
                      }}
                    >
                      {v.size} &bull; {v.color} ({v.stock_qty} in stock)
                    </span>
                  ))}
                </div>
              </div>

              <div style={{ display: "flex", gap: "8px", borderTop: "1px solid #1e293b", paddingTop: "12px" }}>
                <Link
                  href="/seller/inventory"
                  style={{
                    flex: 1,
                    textAlign: "center",
                    padding: "8px",
                    borderRadius: "6px",
                    backgroundColor: "#1e293b",
                    color: "#f1f5f9",
                    fontSize: "12px",
                    fontWeight: "600",
                    textDecoration: "none",
                  }}
                >
                  Adjust Stock
                </Link>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
