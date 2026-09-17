# Privacy Policy for Paridhan

**Effective Date:** September 17, 2026  
**Compliance:** Digital Personal Data Protection Act, 2023 (DPDP Act, India)

Paridhan ("we", "our", or "us") values your privacy. This Privacy Policy details how we collect, process, store, and protect your personal data across the Paridhan platform.

---

## 1. Information We Collect
1. **Identity & Contact Data:** Name, phone number, email address, and profile avatar.
2. **Location Data (Geographical):** Real-time GPS location collected with your explicit consent to discover nearby clothing boutiques and track active deliveries.
3. **Transactional & Payment Data:** Order history, agreed bargain prices, delivery addresses, and payment references (processed via PCI-DSS certified gateway Razorpay).
4. **Partner & Seller KYC Documents:** PAN cards, GST certificates, driving licenses, and vehicle registration numbers for verification.
5. **Optional / Sensitive Data (Phase 2):** Skin tone preferences, collected exclusively upon explicit opt-in for personalized style recommendations.

## 2. Purpose of Processing
- Connecting consumers with local clothing shops within their immediate radius.
- Executing real-time bargaining threads and updating orders.
- Dispatching delivery assignments and providing live map updates.
- Facilitating marketplace settlements through Razorpay Route and tracking COD remittances.
- Preventing fraud and moderating marketplace integrity.

## 3. Data Storage & Security
- All personal data is protected using Row Level Security (RLS) on PostgreSQL instances.
- Geolocation data is queried via PostGIS spatial indexes and is not retained for longer than necessary for order fulfillment and delivery tracking.
- Passwords and auth credentials are encrypted using cryptographic hashing.

## 4. Your Rights under the DPDP Act 2023
You have the right to:
- Access and review your personal data stored with us.
- Request correction or updating of outdated personal data.
- Withdraw consent or request account & data deletion via the in-app Settings menu.
- Nominate a representative or file a grievance.

## 5. Contact
For privacy queries or data deletion requests, contact our Data Protection Officer at:  
**Email:** privacy@paridhan.local
