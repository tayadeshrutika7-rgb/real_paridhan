import RoleGuard from "../../lib/RoleGuard";

export default function SellerLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <RoleGuard allowedRole="seller">{children}</RoleGuard>;
}
