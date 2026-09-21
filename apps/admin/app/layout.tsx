import type { Metadata } from "next";
import "./globals.css";
import { AuthProvider } from "../lib/authContext";
import Navbar from "../components/Navbar";

export const metadata: Metadata = {
  title: "PARIDHAN — Wear Local. Support Local. | Hyperlocal Fashion Marketplace",
  description: "Discover nearby boutique fashion, live bargaining, and instant local delivery dispatch.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ backgroundColor: "#090d16", color: "#f1f5f9", minHeight: "100vh" }}>
        <AuthProvider>
          <Navbar />
          {children}
        </AuthProvider>
      </body>
    </html>
  );
}
