import RoleGuard from "../../lib/RoleGuard";

export default function ConsumerLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <RoleGuard allowedRole="consumer">{children}</RoleGuard>;
}
