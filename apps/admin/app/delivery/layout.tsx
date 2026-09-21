import RoleGuard from "../../lib/RoleGuard";

export default function DeliveryLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <RoleGuard allowedRole="delivery">{children}</RoleGuard>;
}
