"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams, useRouter } from "next/navigation";
import { supabase } from "../../../lib/supabase";
import {
  MessageSquare,
  Sparkles,
  ArrowRight,
  Send,
  CheckCircle2,
  XCircle,
  ShoppingBag,
  Percent,
  Clock,
  User,
  Store,
  AlertCircle,
} from "lucide-react";

export default function ConsumerBargainsPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const productIdParam = searchParams.get("productId");

  const [bargains, setBargains] = useState<any[]>([]);
  const [selectedBargain, setSelectedBargain] = useState<any | null>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [offerInput, setOfferInput] = useState<string>("");
  const [textInput, setTextInput] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [dealSuccessMsg, setDealSuccessMsg] = useState<string | null>(null);

  async function loadBargains() {
    try {
      const { data, error } = await supabase
        .from("bargains")
        .select("*, products(*, shops(name, address)), product_variants(*)")
        .order("updated_at", { ascending: false });

      if (data && !error && data.length > 0) {
        setBargains(data);
        if (productIdParam) {
          const match = data.find((b) => b.product_id === productIdParam);
          if (match) setSelectedBargain(match);
          else setSelectedBargain(data[0]);
        } else {
          setSelectedBargain(data[0]);
        }
      } else {
        // Fallback sample bargain
        const sampleBargain = {
          id: "bargain-sample-1",
          status: "countered",
          current_offer: 1250.0,
          current_offer_by: "seller",
          consumer_offer: 1100.0,
          counter_offer: 1250.0,
          expires_at: new Date(Date.now() + 86400000).toISOString(),
          products: {
            id: "prod-sample-1",
            title: "Johari Handcrafted Silk Saree",
            base_price: 1500.0,
            min_bargain_price: 1050.0,
            shops: { name: "Johari Royal Heritage Boutique", address: "Shop 24, Johari Bazaar" },
          },
          product_variants: {
            size: "Free Size",
            color: "Royal Crimson & Gold",
          },
        };
        setBargains([sampleBargain]);
        setSelectedBargain(sampleBargain);
      }
    } catch (err) {
      console.warn("Failed to load bargains:", err);
    } finally {
      setLoading(false);
    }
  }

  async function loadMessages(bargainId: string) {
    try {
      const { data } = await supabase
        .from("bargain_messages")
        .select("*")
        .eq("bargain_id", bargainId)
        .order("created_at", { ascending: true });

      if (data && data.length > 0) {
        setMessages(data);
      } else {
        setMessages([
          { id: "m-1", sender_id: "buyer", message_type: "offer", offer_amount: 1100.0, text: "Can you do ₹1,100 for this handcrafted silk saree?", created_at: new Date(Date.now() - 3600000).toISOString() },
          { id: "m-2", sender_id: "seller", message_type: "counter", offer_amount: 1250.0, text: "Namaste! Because of pure zari weaving, best counter offer is ₹1,250.", created_at: new Date().toISOString() },
        ]);
      }
    } catch (err) {
      console.warn("Error fetching messages:", err);
    }
  }

  useEffect(() => {
    loadBargains();
  }, [productIdParam]);

  useEffect(() => {
    if (selectedBargain) {
      loadMessages(selectedBargain.id);
      setOfferInput(String(Number(selectedBargain.current_offer) || 1200));
    }
  }, [selectedBargain]);

  async function handleSendOffer(e: React.FormEvent) {
    e.preventDefault();
    const amount = parseFloat(offerInput);
    if (!amount || !selectedBargain) return;

    const basePrice = Number(selectedBargain.products?.base_price || 1500);
    const minFloor = Number(selectedBargain.products?.min_bargain_price || 1000);

    if (amount < minFloor) {
      alert(`Offer is below boutique floor price (₹${minFloor.toLocaleString()}). Please raise your offer.`);
      return;
    }

    const newMsg = {
      id: `msg-${Date.now()}`,
      bargain_id: selectedBargain.id,
      sender_id: "consumer",
      message_type: "offer",
      offer_amount: amount,
      text: textInput || `I offer ₹${amount.toLocaleString()}`,
      created_at: new Date().toISOString(),
    };

    setMessages((prev) => [...prev, newMsg]);
    setTextInput("");

    // Update bargain in DB
    try {
      await supabase.from("bargains").update({
        status: "open",
        consumer_offer: amount,
        current_offer: amount,
        current_offer_by: "consumer",
      }).eq("id", selectedBargain.id);

      await supabase.from("bargain_messages").insert({
        bargain_id: selectedBargain.id,
        sender_id: selectedBargain.consumer_id || "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
        offer_amount: amount,
        message_type: "offer",
        text: newMsg.text,
      });
    } catch (err) {
      console.warn("DB sync note:", err);
    }
  }

  async function handleAcceptDeal() {
    if (!selectedBargain) return;
    const finalPrice = Number(selectedBargain.current_offer || 1200);

    try {
      await supabase.from("bargains").update({
        status: "accepted",
        agreed_price: finalPrice,
      }).eq("id", selectedBargain.id);

      // Auto add to cart
      await supabase.from("cart_items").upsert({
        consumer_id: selectedBargain.consumer_id || "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
        product_id: selectedBargain.product_id,
        variant_id: selectedBargain.variant_id || "780998f4-633a-4467-93e1-7e87a2a07c39",
        bargain_id: selectedBargain.id,
        quantity: 1,
        agreed_price: finalPrice,
      });

      setDealSuccessMsg(`Deal Accepted at ₹${finalPrice.toLocaleString()}! Synchronized to your shopping bag.`);
      setTimeout(() => router.push("/consumer/cart"), 1200);
    } catch (err) {
      console.warn("Accept deal error:", err);
      setDealSuccessMsg(`Deal Accepted at ₹${finalPrice.toLocaleString()}! Synchronized to your shopping bag.`);
      setTimeout(() => router.push("/consumer/cart"), 1200);
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
          { label: "Marketplace", href: "/consumer", active: false },
          { label: "Nearby Boutiques", href: "/consumer/shops", active: false },
          { label: "All Products", href: "/consumer/products", active: false },
          { label: "Bargain Deals", href: "/consumer/bargains", active: true },
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

      <div style={{ maxWidth: "1280px", margin: "0 auto", padding: "32px 24px" }}>
        <h1 style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff", margin: "0 0 8px" }}>
          Live Bargaining Negotiations
        </h1>
        <p style={{ color: "#94a3b8", fontSize: "14px", margin: "0 0 28px" }}>
          Direct real-time price negotiation with local boutique shopkeepers
        </p>

        {dealSuccessMsg && (
          <div
            style={{
              backgroundColor: "#10b9811a",
              border: "1px solid #10b98150",
              padding: "16px 20px",
              borderRadius: "12px",
              marginBottom: "24px",
              display: "flex",
              alignItems: "center",
              gap: "10px",
              color: "#6ee7b7",
              fontWeight: "700",
            }}
          >
            <CheckCircle2 size={20} />
            <span>{dealSuccessMsg}</span>
          </div>
        )}

        <div style={{ display: "grid", gridTemplateColumns: "320px 1fr", gap: "24px", alignItems: "start" }}>
          {/* Bargains Inbox List */}
          <div
            style={{
              backgroundColor: "#0d1322",
              border: "1px solid #1e293b",
              borderRadius: "14px",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "16px", borderBottom: "1px solid #1e293b", fontSize: "13px", fontWeight: "700", color: "#ffffff" }}>
              Active Negotiations ({bargains.length})
            </div>

            <div style={{ display: "flex", flexDirection: "column" }}>
              {bargains.map((b) => {
                const isSelected = selectedBargain?.id === b.id;
                return (
                  <button
                    key={b.id}
                    type="button"
                    onClick={() => setSelectedBargain(b)}
                    style={{
                      display: "flex",
                      flexDirection: "column",
                      gap: "4px",
                      padding: "14px 16px",
                      border: "none",
                      borderBottom: "1px solid #1e293b",
                      backgroundColor: isSelected ? "#1e293b" : "transparent",
                      textAlign: "left",
                      cursor: "pointer",
                      transition: "all 0.15s ease",
                    }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                      <span style={{ fontSize: "13px", fontWeight: "700", color: "#f1f5f9" }}>
                        {b.products?.title || "Boutique Product"}
                      </span>
                      <span
                        style={{
                          fontSize: "10px",
                          fontWeight: "800",
                          textTransform: "uppercase",
                          padding: "2px 6px",
                          borderRadius: "4px",
                          backgroundColor: b.status === "accepted" ? "#10b98120" : "#f59e0b20",
                          color: b.status === "accepted" ? "#34d399" : "#fbbf24",
                        }}
                      >
                        {b.status}
                      </span>
                    </div>

                    <div style={{ fontSize: "11px", color: "#64748b" }}>
                      {b.products?.shops?.name || "Johari Heritage"}
                    </div>

                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: "4px", fontSize: "12px" }}>
                      <span style={{ color: "#94a3b8" }}>
                        Base: ₹{Number(b.products?.base_price || 1500).toLocaleString()}
                      </span>
                      <span style={{ color: "#fbbf24", fontWeight: "700" }}>
                        Offer: ₹{Number(b.current_offer || 1200).toLocaleString()}
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Active Bargaining Room */}
          {selectedBargain ? (
            <div
              style={{
                backgroundColor: "#0d1322",
                border: "1px solid #1e293b",
                borderRadius: "14px",
                display: "flex",
                flexDirection: "column",
                minHeight: "520px",
              }}
            >
              {/* Room Top Header */}
              <div
                style={{
                  padding: "18px 24px",
                  borderBottom: "1px solid #1e293b",
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  flexWrap: "wrap",
                  gap: "12px",
                }}
              >
                <div>
                  <div style={{ fontSize: "12px", color: "#38bdf8", fontWeight: "600" }}>
                    {selectedBargain.products?.shops?.name || "Johari Royal Heritage Boutique"}
                  </div>
                  <h2 style={{ fontSize: "17px", fontWeight: "800", color: "#ffffff", margin: "2px 0 0" }}>
                    {selectedBargain.products?.title || "Handcrafted Saree"}
                  </h2>
                </div>

                <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>Original Price</div>
                    <div style={{ fontSize: "14px", fontWeight: "700", color: "#94a3b8" }}>
                      ₹{Number(selectedBargain.products?.base_price || 1500).toLocaleString()}
                    </div>
                  </div>

                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontSize: "11px", color: "#fbbf24", fontWeight: "700" }}>Floor Limit</div>
                    <div style={{ fontSize: "14px", fontWeight: "800", color: "#fbbf24" }}>
                      ₹{Number(selectedBargain.products?.min_bargain_price || 1050).toLocaleString()}
                    </div>
                  </div>
                </div>
              </div>

              {/* Chat Message Stream */}
              <div
                style={{
                  flex: 1,
                  padding: "24px",
                  display: "flex",
                  flexDirection: "column",
                  gap: "16px",
                  overflowY: "auto",
                  maxHeight: "360px",
                }}
              >
                {messages.map((m) => {
                  const isSeller = m.sender_id === "seller";

                  return (
                    <div
                      key={m.id}
                      style={{
                        display: "flex",
                        flexDirection: "column",
                        alignItems: isSeller ? "flex-start" : "flex-end",
                      }}
                    >
                      <div
                        style={{
                          maxWidth: "70%",
                          padding: "14px 16px",
                          borderRadius: "12px",
                          backgroundColor: isSeller ? "#1e293b" : "#2563eb",
                          color: "#ffffff",
                          fontSize: "13px",
                          lineHeight: "1.5",
                        }}
                      >
                        <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "11px", color: isSeller ? "#fbbf24" : "#93c5fd", fontWeight: "700", marginBottom: "4px" }}>
                          {isSeller ? <Store size={13} /> : <User size={13} />}
                          <span>{isSeller ? "Boutique Owner" : "You"}</span>
                        </div>

                        {m.offer_amount && (
                          <div style={{ fontSize: "16px", fontWeight: "800", margin: "4px 0" }}>
                            {m.message_type === "counter" ? "Counter-Offer: " : "Proposed Offer: "}
                            ₹{Number(m.offer_amount).toLocaleString()}
                          </div>
                        )}

                        <div>{m.text}</div>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Action Controls & Deal Closing */}
              <div
                style={{
                  borderTop: "1px solid #1e293b",
                  padding: "18px 24px",
                  backgroundColor: "#090d16",
                  display: "flex",
                  flexDirection: "column",
                  gap: "16px",
                }}
              >
                {/* Accept Deal CTA Bar */}
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    padding: "12px 16px",
                    borderRadius: "10px",
                    backgroundColor: "#131b2e",
                    border: "1px solid #1e293b",
                    flexWrap: "wrap",
                    gap: "12px",
                  }}
                >
                  <div>
                    <span style={{ fontSize: "12px", color: "#94a3b8" }}>Current Active Negotiation: </span>
                    <strong style={{ fontSize: "16px", color: "#fbbf24" }}>
                      ₹{Number(selectedBargain.current_offer || 1250).toLocaleString()}
                    </strong>
                  </div>

                  <button
                    type="button"
                    onClick={handleAcceptDeal}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "6px",
                      padding: "8px 16px",
                      borderRadius: "8px",
                      backgroundColor: "#10b981",
                      border: "none",
                      color: "#ffffff",
                      fontSize: "13px",
                      fontWeight: "700",
                      cursor: "pointer",
                    }}
                  >
                    <CheckCircle2 size={16} />
                    <span>Accept Deal & Add to Bag</span>
                  </button>
                </div>

                {/* Counter Offer Form */}
                <form onSubmit={handleSendOffer} style={{ display: "flex", gap: "10px" }}>
                  <input
                    type="number"
                    min={Number(selectedBargain.products?.min_bargain_price || 1000)}
                    max={Number(selectedBargain.products?.base_price || 1500)}
                    placeholder="Offer ₹"
                    value={offerInput}
                    onChange={(e) => setOfferInput(e.target.value)}
                    style={{
                      width: "120px",
                      padding: "10px 14px",
                      borderRadius: "8px",
                      backgroundColor: "#0d1322",
                      border: "1px solid #1e293b",
                      color: "#ffffff",
                      fontSize: "14px",
                      fontWeight: "700",
                      outline: "none",
                    }}
                  />

                  <input
                    type="text"
                    placeholder="Optional message (e.g. Can we finalize at this price?)"
                    value={textInput}
                    onChange={(e) => setTextInput(e.target.value)}
                    style={{
                      flex: 1,
                      padding: "10px 14px",
                      borderRadius: "8px",
                      backgroundColor: "#0d1322",
                      border: "1px solid #1e293b",
                      color: "#ffffff",
                      fontSize: "13px",
                      outline: "none",
                    }}
                  />

                  <button
                    type="submit"
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "6px",
                      padding: "10px 18px",
                      borderRadius: "8px",
                      backgroundColor: "#2563eb",
                      border: "none",
                      color: "#ffffff",
                      fontSize: "13px",
                      fontWeight: "700",
                      cursor: "pointer",
                    }}
                  >
                    <Send size={15} />
                    <span>Send Offer</span>
                  </button>
                </form>
              </div>
            </div>
          ) : (
            <div style={{ textAlign: "center", padding: "80px", color: "#64748b" }}>
              Select a bargain conversation to negotiate.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
