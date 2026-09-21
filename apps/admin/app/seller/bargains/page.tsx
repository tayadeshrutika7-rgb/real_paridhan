"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "../../../lib/supabase";
import {
  MessageSquare,
  Sparkles,
  Send,
  CheckCircle2,
  XCircle,
  Percent,
  Clock,
  User,
  Store,
  AlertCircle,
} from "lucide-react";

export default function SellerBargainsPage() {
  const [bargains, setBargains] = useState<any[]>([]);
  const [selectedBargain, setSelectedBargain] = useState<any | null>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [counterInput, setCounterInput] = useState<string>("");
  const [textInput, setTextInput] = useState<string>("");
  const [statusMsg, setStatusMsg] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  async function loadBargains() {
    try {
      const { data, error } = await supabase
        .from("bargains")
        .select("*, products(*, product_variants(*)), profiles:consumer_id(*)")
        .order("updated_at", { ascending: false });

      if (data && !error && data.length > 0) {
        setBargains(data);
        setSelectedBargain(data[0]);
      } else {
        const sample = {
          id: "bargain-seller-1",
          status: "open",
          current_offer: 1100.0,
          current_offer_by: "consumer",
          consumer_offer: 1100.0,
          counter_offer: null,
          products: {
            title: "Johari Handcrafted Silk Saree",
            base_price: 1500.0,
            min_bargain_price: 1050.0,
          },
          profiles: {
            full_name: "Priya Sharma",
            email: "buyer1@gm.com",
          },
        };
        setBargains([sample]);
        setSelectedBargain(sample);
      }
    } catch (err) {
      console.warn("Error loading seller bargains:", err);
    } finally {
      setLoading(false);
    }
  }

  async function loadMessages(bId: string) {
    try {
      const { data } = await supabase
        .from("bargain_messages")
        .select("*")
        .eq("bargain_id", bId)
        .order("created_at", { ascending: true });

      if (data && data.length > 0) {
        setMessages(data);
      } else {
        setMessages([
          { id: "m-1", sender_id: "buyer", message_type: "offer", offer_amount: 1100.0, text: "Can you offer a discount for festive season?", created_at: new Date().toISOString() },
        ]);
      }
    } catch (err) {
      console.warn("Failed to load messages:", err);
    }
  }

  useEffect(() => {
    loadBargains();
  }, []);

  useEffect(() => {
    if (selectedBargain) {
      loadMessages(selectedBargain.id);
      setCounterInput(String(Number(selectedBargain.current_offer) || 1250));
    }
  }, [selectedBargain]);

  async function handleSendCounter(e: React.FormEvent) {
    e.preventDefault();
    const amount = parseFloat(counterInput);
    if (!amount || !selectedBargain) return;

    const minFloor = Number(selectedBargain.products?.min_bargain_price || 1050);
    if (amount < minFloor) {
      alert(`Counter offer cannot be lower than your protected boutique floor price (₹${minFloor.toLocaleString()})`);
      return;
    }

    const newMsg = {
      id: `msg-${Date.now()}`,
      bargain_id: selectedBargain.id,
      sender_id: "seller",
      message_type: "counter",
      offer_amount: amount,
      text: textInput || `We can offer this authentic handcrafted piece at ₹${amount.toLocaleString()}`,
      created_at: new Date().toISOString(),
    };

    setMessages((prev) => [...prev, newMsg]);
    setTextInput("");

    try {
      await supabase.from("bargains").update({
        status: "countered",
        counter_offer: amount,
        current_offer: amount,
        current_offer_by: "seller",
      }).eq("id", selectedBargain.id);

      await supabase.from("bargain_messages").insert({
        bargain_id: selectedBargain.id,
        sender_id: selectedBargain.seller_id || "780998f4-633a-4467-93e1-7e87a2a07c39",
        offer_amount: amount,
        message_type: "counter",
        text: newMsg.text,
      });

      setStatusMsg(`Counter offer of ₹${amount.toLocaleString()} sent to buyer!`);
      setTimeout(() => setStatusMsg(null), 3000);
    } catch (err) {
      console.warn("Counter send note:", err);
    }
  }

  async function handleAcceptBuyerOffer() {
    if (!selectedBargain) return;
    const agreed = Number(selectedBargain.current_offer || 1100);

    try {
      await supabase.from("bargains").update({
        status: "accepted",
        agreed_price: agreed,
      }).eq("id", selectedBargain.id);

      setStatusMsg(`Buyer offer accepted at ₹${agreed.toLocaleString()}! Deal synchronized to buyer bag.`);
      setTimeout(() => setStatusMsg(null), 3000);
    } catch (err) {
      console.warn("Accept error:", err);
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
          { label: "Catalog & Products", href: "/seller/products", active: false },
          { label: "Orders Fulfillment", href: "/seller/orders", active: false },
          { label: "Bargain Inbox", href: "/seller/bargains", active: true },
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
        <h1 style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff", margin: "0 0 8px" }}>
          Seller Bargaining Inbox & Counter-Offers
        </h1>
        <p style={{ color: "#94a3b8", fontSize: "14px", margin: "0 0 28px" }}>
          Review incoming buyer offers, respond with counter-offers, or accept deals with floor protection
        </p>

        {statusMsg && (
          <div
            style={{
              padding: "14px 18px",
              borderRadius: "10px",
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
            <span>{statusMsg}</span>
          </div>
        )}

        <div style={{ display: "grid", gridTemplateColumns: "340px 1fr", gap: "24px", alignItems: "start" }}>
          {/* Incoming Offers List */}
          <div
            style={{
              backgroundColor: "#0d1322",
              border: "1px solid #1e293b",
              borderRadius: "14px",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "16px", borderBottom: "1px solid #1e293b", fontSize: "13px", fontWeight: "700", color: "#ffffff" }}>
              Incoming Customer Bargains ({bargains.length})
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
                    }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                      <span style={{ fontSize: "13px", fontWeight: "700", color: "#ffffff" }}>
                        {b.products?.title || "Boutique Product"}
                      </span>
                      <span
                        style={{
                          fontSize: "10px",
                          fontWeight: "800",
                          textTransform: "uppercase",
                          padding: "2px 6px",
                          borderRadius: "4px",
                          backgroundColor: "#f59e0b20",
                          color: "#fbbf24",
                        }}
                      >
                        {b.status}
                      </span>
                    </div>

                    <div style={{ fontSize: "11px", color: "#64748b" }}>
                      Buyer: {b.profiles?.full_name || "Priya Sharma"}
                    </div>

                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: "4px", fontSize: "12px" }}>
                      <span style={{ color: "#94a3b8" }}>
                        Base: ₹{Number(b.products?.base_price || 1500).toLocaleString()}
                      </span>
                      <span style={{ color: "#fbbf24", fontWeight: "700" }}>
                        Offer: ₹{Number(b.current_offer || 1100).toLocaleString()}
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Chat & Counter Proposal Window */}
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
              {/* Header */}
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
                  <div style={{ fontSize: "12px", color: "#fbbf24", fontWeight: "600" }}>
                    Buyer: {selectedBargain.profiles?.full_name || "Priya Sharma"}
                  </div>
                  <h2 style={{ fontSize: "17px", fontWeight: "800", color: "#ffffff", margin: "2px 0 0" }}>
                    {selectedBargain.products?.title || "Handcrafted Saree"}
                  </h2>
                </div>

                <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>Catalog Base</div>
                    <div style={{ fontSize: "14px", fontWeight: "700", color: "#94a3b8" }}>
                      ₹{Number(selectedBargain.products?.base_price || 1500).toLocaleString()}
                    </div>
                  </div>

                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontSize: "11px", color: "#fbbf24", fontWeight: "700" }}>Your Protected Floor</div>
                    <div style={{ fontSize: "14px", fontWeight: "800", color: "#fbbf24" }}>
                      ₹{Number(selectedBargain.products?.min_bargain_price || 1050).toLocaleString()}
                    </div>
                  </div>
                </div>
              </div>

              {/* Messages Stream */}
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
                        alignItems: isSeller ? "flex-end" : "flex-start",
                      }}
                    >
                      <div
                        style={{
                          maxWidth: "70%",
                          padding: "14px 16px",
                          borderRadius: "12px",
                          backgroundColor: isSeller ? "#f59e0b20" : "#1e293b",
                          border: `1px solid ${isSeller ? "#f59e0b40" : "#334155"}`,
                          color: "#ffffff",
                          fontSize: "13px",
                          lineHeight: "1.5",
                        }}
                      >
                        <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "11px", color: isSeller ? "#fbbf24" : "#38bdf8", fontWeight: "700", marginBottom: "4px" }}>
                          {isSeller ? <Store size={13} /> : <User size={13} />}
                          <span>{isSeller ? "You (Seller Studio)" : "Buyer"}</span>
                        </div>

                        {m.offer_amount && (
                          <div style={{ fontSize: "16px", fontWeight: "800", color: isSeller ? "#fbbf24" : "#ffffff", margin: "4px 0" }}>
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

              {/* Seller Controls */}
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
                    <span style={{ fontSize: "12px", color: "#94a3b8" }}>Buyer's Last Proposed Price: </span>
                    <strong style={{ fontSize: "16px", color: "#ffffff" }}>
                      ₹{Number(selectedBargain.current_offer || 1100).toLocaleString()}
                    </strong>
                  </div>

                  <button
                    type="button"
                    onClick={handleAcceptBuyerOffer}
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
                    <span>Accept Customer Offer</span>
                  </button>
                </div>

                {/* Counter Offer Box */}
                <form onSubmit={handleSendCounter} style={{ display: "flex", gap: "10px" }}>
                  <input
                    type="number"
                    min={Number(selectedBargain.products?.min_bargain_price || 1050)}
                    max={Number(selectedBargain.products?.base_price || 1500)}
                    placeholder="Counter ₹"
                    value={counterInput}
                    onChange={(e) => setCounterInput(e.target.value)}
                    style={{
                      width: "120px",
                      padding: "10px 14px",
                      borderRadius: "8px",
                      backgroundColor: "#0d1322",
                      border: "1px solid #fbbf2440",
                      color: "#fbbf24",
                      fontSize: "14px",
                      fontWeight: "700",
                      outline: "none",
                    }}
                  />

                  <input
                    type="text"
                    placeholder="Counter message (e.g. Best price considering pure zari finish)"
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
                      backgroundColor: "#f59e0b",
                      border: "none",
                      color: "#000000",
                      fontSize: "13px",
                      fontWeight: "700",
                      cursor: "pointer",
                    }}
                  >
                    <Send size={15} />
                    <span>Send Counter</span>
                  </button>
                </form>
              </div>
            </div>
          ) : (
            <div style={{ textAlign: "center", padding: "80px", color: "#64748b" }}>
              Select an offer from the inbox.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
