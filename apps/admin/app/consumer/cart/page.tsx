"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "../../../lib/supabase";
import {
  ShoppingBag,
  Trash2,
  Plus,
  Minus,
  ArrowRight,
  Sparkles,
  ShieldCheck,
  Tag,
  MessageSquare,
} from "lucide-react";

export default function CartPage() {
  const router = useRouter();
  const [cartItems, setCartItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  async function loadCart() {
    try {
      const { data, error } = await supabase
        .from("cart_items")
        .select("*, products(*, shops(name, address)), product_variants(*)");

      if (data && !error && data.length > 0) {
        setCartItems(data);
      } else {
        // Mock sample if empty
        setCartItems([
          {
            id: "cart-item-1",
            quantity: 1,
            agreed_price: 1200.0,
            products: {
              id: "prod-1",
              title: "Johari Handcrafted Silk Saree",
              base_price: 1500.0,
              shops: { name: "Johari Royal Heritage Boutique", address: "Shop 24, Johari Bazaar" },
            },
            product_variants: {
              size: "Free Size",
              color: "Royal Crimson & Gold",
            },
          },
        ]);
      }
    } catch (err) {
      console.warn("Failed to load cart items:", err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadCart();
  }, []);

  async function updateQty(id: string, newQty: number) {
    if (newQty <= 0) {
      deleteItem(id);
      return;
    }
    setCartItems((prev) =>
      prev.map((item) => (item.id === id ? { ...item, quantity: newQty } : item))
    );
    try {
      await supabase.from("cart_items").update({ quantity: newQty }).eq("id", id);
    } catch (err) {
      console.warn("Could not sync qty to DB:", err);
    }
  }

  async function deleteItem(id: string) {
    setCartItems((prev) => prev.filter((item) => item.id !== id));
    try {
      await supabase.from("cart_items").delete().eq("id", id);
    } catch (err) {
      console.warn("Could not delete from DB:", err);
    }
  }

  const subtotal = cartItems.reduce((acc, item) => {
    const price = Number(item.agreed_price || item.products?.base_price || 1200);
    return acc + price * (item.quantity || 1);
  }, 0);

  const deliveryFee = subtotal > 999 ? 0 : 35;
  const platformFee = 15;
  const totalAmount = subtotal + deliveryFee + platformFee;

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
          { label: "All Products", href: "/consumer/products", active: false },
          { label: "Bargain Deals", href: "/consumer/bargains", active: false },
          { label: "Shopping Bag", href: "/consumer/cart", active: true },
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

      <div style={{ maxWidth: "1100px", margin: "0 auto", padding: "32px 24px" }}>
        <h1 style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff", margin: "0 0 8px" }}>
          Your Shopping Bag
        </h1>
        <p style={{ color: "#94a3b8", fontSize: "14px", margin: "0 0 32px" }}>
          Verified boutique items and agreed bargain pricing
        </p>

        {loading ? (
          <div style={{ textAlign: "center", padding: "60px", color: "#94a3b8" }}>
            Loading shopping bag items...
          </div>
        ) : cartItems.length === 0 ? (
          <div
            style={{
              textAlign: "center",
              padding: "60px 24px",
              backgroundColor: "#0d1322",
              borderRadius: "16px",
              border: "1px solid #1e293b",
            }}
          >
            <ShoppingBag size={48} style={{ color: "#64748b", margin: "0 auto 16px" }} />
            <h2 style={{ fontSize: "18px", fontWeight: "700", color: "#ffffff", marginBottom: "8px" }}>
              Your shopping bag is empty
            </h2>
            <p style={{ color: "#94a3b8", fontSize: "13px", marginBottom: "24px" }}>
              Explore nearby boutiques and bargain for authentic local fashion.
            </p>
            <Link
              href="/consumer/products"
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: "8px",
                backgroundColor: "#f43f5e",
                color: "#ffffff",
                padding: "10px 20px",
                borderRadius: "8px",
                fontWeight: "700",
                fontSize: "13px",
                textDecoration: "none",
              }}
            >
              Browse Catalog &rarr;
            </Link>
          </div>
        ) : (
          <div style={{ display: "grid", gridTemplateColumns: "1fr 340px", gap: "28px", alignItems: "start" }}>
            {/* Items List */}
            <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
              {cartItems.map((item) => {
                const isBargainPrice = !!item.agreed_price;
                const activePrice = Number(item.agreed_price || item.products?.base_price || 1200);
                const originalPrice = Number(item.products?.base_price || 1500);

                return (
                  <div
                    key={item.id}
                    style={{
                      backgroundColor: "#0d1322",
                      border: "1px solid #1e293b",
                      borderRadius: "14px",
                      padding: "20px",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      gap: "16px",
                      flexWrap: "wrap",
                    }}
                  >
                    <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
                      <div
                        style={{
                          width: "60px",
                          height: "60px",
                          borderRadius: "10px",
                          backgroundColor: "#1e293b",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          fontSize: "28px",
                        }}
                      >
                        👗
                      </div>

                      <div>
                        <div style={{ fontSize: "11px", color: "#38bdf8", fontWeight: "600" }}>
                          {item.products?.shops?.name || "Johari Royal Heritage Boutique"}
                        </div>
                        <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#ffffff", margin: "2px 0 4px" }}>
                          {item.products?.title || "Ethnic Handcrafted Outfit"}
                        </h3>
                        <div style={{ fontSize: "12px", color: "#94a3b8", display: "flex", alignItems: "center", gap: "8px" }}>
                          <span>Size: {item.product_variants?.size || "M"}</span>
                          <span>&bull;</span>
                          <span>Color: {item.product_variants?.color || "Crimson"}</span>
                        </div>

                        {isBargainPrice && (
                          <div
                            style={{
                              display: "inline-flex",
                              alignItems: "center",
                              gap: "4px",
                              marginTop: "6px",
                              padding: "2px 8px",
                              borderRadius: "4px",
                              backgroundColor: "#f59e0b15",
                              border: "1px solid #f59e0b35",
                              color: "#fbbf24",
                              fontSize: "11px",
                              fontWeight: "700",
                            }}
                          >
                            <Sparkles size={11} /> Agreed Bargain Price (Saved ₹{(originalPrice - activePrice).toLocaleString()})
                          </div>
                        )}
                      </div>
                    </div>

                    <div style={{ display: "flex", alignItems: "center", gap: "24px" }}>
                      {/* Pricing */}
                      <div style={{ textAlign: "right" }}>
                        <div style={{ fontSize: "18px", fontWeight: "800", color: "#ffffff" }}>
                          ₹{(activePrice * (item.quantity || 1)).toLocaleString()}
                        </div>
                        {isBargainPrice && (
                          <div style={{ fontSize: "12px", color: "#64748b", textDecoration: "line-through" }}>
                            ₹{(originalPrice * (item.quantity || 1)).toLocaleString()}
                          </div>
                        )}
                      </div>

                      {/* Quantity Controls */}
                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          backgroundColor: "#090d16",
                          border: "1px solid #1e293b",
                          borderRadius: "8px",
                          padding: "4px",
                        }}
                      >
                        <button
                          type="button"
                          onClick={() => updateQty(item.id, (item.quantity || 1) - 1)}
                          style={{
                            width: "28px",
                            height: "28px",
                            borderRadius: "6px",
                            backgroundColor: "transparent",
                            border: "none",
                            color: "#94a3b8",
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                          }}
                        >
                          <Minus size={14} />
                        </button>
                        <span style={{ padding: "0 10px", fontSize: "13px", fontWeight: "700", color: "#ffffff" }}>
                          {item.quantity || 1}
                        </span>
                        <button
                          type="button"
                          onClick={() => updateQty(item.id, (item.quantity || 1) + 1)}
                          style={{
                            width: "28px",
                            height: "28px",
                            borderRadius: "6px",
                            backgroundColor: "transparent",
                            border: "none",
                            color: "#94a3b8",
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                          }}
                        >
                          <Plus size={14} />
                        </button>
                      </div>

                      {/* Delete */}
                      <button
                        type="button"
                        onClick={() => deleteItem(item.id)}
                        style={{
                          backgroundColor: "transparent",
                          border: "none",
                          color: "#f43f5e",
                          cursor: "pointer",
                          padding: "6px",
                        }}
                        title="Remove"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Order Summary Box */}
            <div
              style={{
                backgroundColor: "#0d1322",
                border: "1px solid #1e293b",
                borderRadius: "16px",
                padding: "24px",
              }}
            >
              <h2 style={{ fontSize: "16px", fontWeight: "700", color: "#ffffff", margin: "0 0 16px" }}>
                Price Details
              </h2>

              <div style={{ display: "flex", flexDirection: "column", gap: "12px", fontSize: "13px", marginBottom: "20px" }}>
                <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8" }}>
                  <span>Items Subtotal</span>
                  <span style={{ color: "#f1f5f9", fontWeight: "600" }}>₹{subtotal.toLocaleString()}</span>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8" }}>
                  <span>Delivery Dispatch</span>
                  <span style={{ color: deliveryFee === 0 ? "#34d399" : "#f1f5f9", fontWeight: "600" }}>
                    {deliveryFee === 0 ? "FREE" : `₹${deliveryFee}`}
                  </span>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8" }}>
                  <span>Platform Fee</span>
                  <span style={{ color: "#f1f5f9", fontWeight: "600" }}>₹{platformFee}</span>
                </div>

                <div style={{ borderTop: "1px solid #1e293b", paddingTop: "12px", display: "flex", justifyContent: "space-between", fontSize: "16px", fontWeight: "800", color: "#ffffff" }}>
                  <span>Total Payable</span>
                  <span style={{ color: "#f43f5e" }}>₹{totalAmount.toLocaleString()}</span>
                </div>
              </div>

              <Link
                href="/consumer/checkout"
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "8px",
                  padding: "12px",
                  borderRadius: "8px",
                  backgroundColor: "#f43f5e",
                  color: "#ffffff",
                  fontSize: "14px",
                  fontWeight: "700",
                  textDecoration: "none",
                  boxShadow: "0 8px 20px rgba(244,63,94,0.3)",
                }}
              >
                <span>Proceed to Checkout</span>
                <ArrowRight size={16} />
              </Link>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
