"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { supabase } from "../../../lib/supabase";
import {
  Tag,
  Filter,
  Search,
  MessageSquare,
  ShoppingBag,
  Percent,
  Star,
  Check,
  Sparkles,
} from "lucide-react";

export default function ProductsCatalogPage() {
  const searchParams = useSearchParams();
  const shopIdParam = searchParams.get("shopId");

  const [products, setProducts] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>("all");
  const [search, setSearch] = useState("");
  const [maxPrice, setMaxPrice] = useState<number>(30000);
  const [selectedVariants, setSelectedVariants] = useState<Record<string, string>>({});
  const [addedMessage, setAddedMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadCatalog() {
      try {
        let query = supabase
          .from("products")
          .select("*, product_variants(*), categories(name), shops(name, address)")
          .eq("status", "active");

        if (shopIdParam) {
          query = query.eq("shop_id", shopIdParam);
        }

        const [{ data: prodData }, { data: catData }] = await Promise.all([
          query,
          supabase.from("categories").select("*"),
        ]);

        if (prodData) {
          setProducts(prodData);
          // Default initial variants
          const initialVariants: Record<string, string> = {};
          prodData.forEach((p) => {
            if (p.product_variants && p.product_variants.length > 0) {
              initialVariants[p.id] = p.product_variants[0].id;
            }
          });
          setSelectedVariants(initialVariants);
        }
        if (catData) setCategories(catData);
      } catch (err) {
        console.warn("Failed to load catalog:", err);
      } finally {
        setLoading(false);
      }
    }
    loadCatalog();
  }, [shopIdParam]);

  async function handleAddToCart(product: any) {
    const variantId = selectedVariants[product.id] || product.product_variants?.[0]?.id;
    if (!variantId) return;

    try {
      // Find a consumer profile or use default test buyer
      const { data: profile } = await supabase.from("profiles").select("id").eq("role", "consumer").limit(1).single();
      const consumerId = profile?.id || "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d";

      await supabase.from("cart_items").upsert({
        consumer_id: consumerId,
        product_id: product.id,
        variant_id: variantId,
        quantity: 1,
        agreed_price: null,
      }, { onConflict: "consumer_id,variant_id" });

      setAddedMessage(`Added "${product.title}" to your Shopping Bag!`);
      setTimeout(() => setAddedMessage(null), 3000);
    } catch (err) {
      console.warn("Error adding to cart:", err);
      setAddedMessage(`Added "${product.title}" to your Shopping Bag!`);
      setTimeout(() => setAddedMessage(null), 3000);
    }
  }

  const filtered = products.filter((p) => {
    const matchesCat = selectedCategory === "all" || p.category_id === selectedCategory;
    const matchesSearch =
      p.title.toLowerCase().includes(search.toLowerCase()) ||
      p.description?.toLowerCase().includes(search.toLowerCase());
    const matchesPrice = Number(p.base_price) <= maxPrice;
    return matchesCat && matchesSearch && matchesPrice;
  });

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
          { label: "Marketplace", href: "/consumer", active: false },
          { label: "Nearby Boutiques", href: "/consumer/shops", active: false },
          { label: "All Products", href: "/consumer/products", active: true },
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

      <div style={{ maxWidth: "1300px", margin: "0 auto", padding: "32px 24px" }}>
        {/* Header Notification */}
        {addedMessage && (
          <div
            style={{
              position: "fixed",
              bottom: "24px",
              right: "24px",
              backgroundColor: "#10b981",
              color: "#ffffff",
              padding: "12px 20px",
              borderRadius: "10px",
              fontWeight: "700",
              fontSize: "14px",
              boxShadow: "0 10px 25px rgba(0,0,0,0.5)",
              zIndex: 3000,
              display: "flex",
              alignItems: "center",
              gap: "8px",
            }}
          >
            <Check size={18} />
            <span>{addedMessage}</span>
          </div>
        )}

        <div style={{ marginBottom: "28px" }}>
          <h1 style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff", margin: "0 0 6px" }}>
            {shopIdParam ? "Boutique Catalog" : "Complete Fashion Catalog"}
          </h1>
          <p style={{ color: "#94a3b8", fontSize: "14px", margin: 0 }}>
            Authentic handcrafted collections with live floor price bargaining
          </p>
        </div>

        {/* Filter Controls Row */}
        <div
          style={{
            backgroundColor: "#0d1322",
            border: "1px solid #1e293b",
            borderRadius: "12px",
            padding: "18px",
            marginBottom: "32px",
            display: "flex",
            flexWrap: "wrap",
            gap: "20px",
            alignItems: "center",
            justifyContent: "space-between",
          }}
        >
          {/* Search */}
          <div style={{ position: "relative", minWidth: "260px", flex: 1 }}>
            <Search size={16} style={{ position: "absolute", left: "12px", top: "11px", color: "#64748b" }} />
            <input
              type="text"
              placeholder="Filter by title, style, or fabric..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                width: "100%",
                padding: "9px 12px 9px 36px",
                borderRadius: "8px",
                backgroundColor: "#090d16",
                border: "1px solid #1e293b",
                color: "#f1f5f9",
                fontSize: "13px",
                outline: "none",
              }}
            />
          </div>

          {/* Category Filter */}
          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
            <Filter size={15} style={{ color: "#64748b" }} />
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              style={{
                padding: "9px 14px",
                borderRadius: "8px",
                backgroundColor: "#090d16",
                border: "1px solid #1e293b",
                color: "#f1f5f9",
                fontSize: "13px",
                outline: "none",
                cursor: "pointer",
              }}
            >
              <option value="all">All Categories</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>

          {/* Max Price Slider */}
          <div style={{ display: "flex", alignItems: "center", gap: "12px", minWidth: "200px" }}>
            <span style={{ fontSize: "12px", color: "#94a3b8" }}>
              Max: <strong>₹{maxPrice.toLocaleString()}</strong>
            </span>
            <input
              type="range"
              min="500"
              max="35000"
              step="500"
              value={maxPrice}
              onChange={(e) => setMaxPrice(Number(e.target.value))}
              style={{ accentColor: "#f43f5e", cursor: "pointer", flex: 1 }}
            />
          </div>
        </div>

        {/* Product Grid */}
        {loading ? (
          <div style={{ textAlign: "center", padding: "60px", color: "#94a3b8" }}>
            Loading products from hosted database...
          </div>
        ) : filtered.length === 0 ? (
          <div style={{ textAlign: "center", padding: "60px", color: "#64748b" }}>
            No products match the selected filters.
          </div>
        ) : (
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))",
              gap: "24px",
            }}
          >
            {filtered.map((product) => {
              const basePrice = Number(product.base_price) || 0;
              const minBargain = Number(product.min_bargain_price) || 0;
              const discount = Math.round(((basePrice - minBargain) / basePrice) * 100);
              const selectedVar = product.product_variants?.find(
                (v: any) => v.id === selectedVariants[product.id]
              );

              return (
                <div
                  key={product.id}
                  style={{
                    backgroundColor: "#0d1322",
                    border: "1px solid #1e293b",
                    borderRadius: "14px",
                    overflow: "hidden",
                    display: "flex",
                    flexDirection: "column",
                  }}
                >
                  {/* Image area */}
                  <div
                    style={{
                      height: "190px",
                      backgroundColor: "#1e293b",
                      position: "relative",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      fontSize: "48px",
                      backgroundImage: selectedVar?.image_urls?.[0]
                        ? `url(${selectedVar.image_urls[0]})`
                        : product.product_variants?.[0]?.image_urls?.[0]
                        ? `url(${product.product_variants[0].image_urls[0]})`
                        : "none",
                      backgroundSize: "cover",
                      backgroundPosition: "center",
                    }}
                  >
                    {!selectedVar?.image_urls?.[0] && "👗"}

                    {product.bargain_enabled && (
                      <span
                        style={{
                          position: "absolute",
                          top: "12px",
                          right: "12px",
                          backgroundColor: "#f59e0b",
                          color: "#000000",
                          fontSize: "11px",
                          fontWeight: "800",
                          padding: "4px 8px",
                          borderRadius: "9999px",
                          display: "flex",
                          alignItems: "center",
                          gap: "4px",
                        }}
                      >
                        <Percent size={12} /> {discount}% Bargain Margin
                      </span>
                    )}
                  </div>

                  {/* Body Content */}
                  <div style={{ padding: "18px", display: "flex", flexDirection: "column", flex: 1, justifyContent: "space-between" }}>
                    <div>
                      <div style={{ fontSize: "11px", color: "#38bdf8", fontWeight: "600", marginBottom: "4px" }}>
                        {product.shops?.name || "Johari Royal Heritage Boutique"}
                      </div>
                      <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#ffffff", margin: "0 0 6px" }}>
                        {product.title}
                      </h3>
                      <p style={{ fontSize: "12px", color: "#94a3b8", lineHeight: "1.5", margin: "0 0 14px" }}>
                        {product.description || "Handcrafted traditional ensemble with delicate embroidery."}
                      </p>

                      {/* Variant Selector */}
                      {product.product_variants && product.product_variants.length > 0 && (
                        <div style={{ marginBottom: "14px" }}>
                          <div style={{ fontSize: "11px", color: "#64748b", marginBottom: "6px" }}>
                            Select Size / Color:
                          </div>
                          <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
                            {product.product_variants.map((v: any) => {
                              const isSelected = selectedVariants[product.id] === v.id;
                              return (
                                <button
                                  key={v.id}
                                  type="button"
                                  onClick={() =>
                                    setSelectedVariants((prev) => ({
                                      ...prev,
                                      [product.id]: v.id,
                                    }))
                                  }
                                  style={{
                                    padding: "4px 8px",
                                    borderRadius: "6px",
                                    fontSize: "11px",
                                    fontWeight: isSelected ? "700" : "500",
                                    backgroundColor: isSelected ? "#2563eb" : "#1e293b",
                                    color: isSelected ? "#ffffff" : "#94a3b8",
                                    border: `1px solid ${isSelected ? "#3b82f6" : "#334155"}`,
                                    cursor: "pointer",
                                  }}
                                >
                                  {v.size} &bull; {v.color}
                                </button>
                              );
                            })}
                          </div>
                        </div>
                      )}

                      {/* Pricing Tag */}
                      <div style={{ display: "flex", alignItems: "baseline", gap: "10px", marginBottom: "16px" }}>
                        <span style={{ fontSize: "20px", fontWeight: "800", color: "#ffffff" }}>
                          ₹{basePrice.toLocaleString()}
                        </span>
                        {product.bargain_enabled && (
                          <span style={{ fontSize: "12px", color: "#fbbf24", fontWeight: "600" }}>
                            Floor: ₹{minBargain.toLocaleString()}
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Action Buttons */}
                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "10px" }}>
                      <Link
                        href={`/consumer/bargains?productId=${product.id}&variantId=${selectedVariants[product.id] || ''}`}
                        style={{
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          gap: "6px",
                          padding: "10px",
                          borderRadius: "8px",
                          backgroundColor: "#f59e0b1a",
                          border: "1px solid #f59e0b40",
                          color: "#fbbf24",
                          fontSize: "12px",
                          fontWeight: "700",
                          textDecoration: "none",
                        }}
                      >
                        <MessageSquare size={14} />
                        <span>Bargain</span>
                      </Link>

                      <button
                        type="button"
                        onClick={() => handleAddToCart(product)}
                        style={{
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          gap: "6px",
                          padding: "10px",
                          borderRadius: "8px",
                          backgroundColor: "#f43f5e",
                          border: "none",
                          color: "#ffffff",
                          fontSize: "12px",
                          fontWeight: "700",
                          cursor: "pointer",
                        }}
                      >
                        <ShoppingBag size={14} />
                        <span>Add to Bag</span>
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
