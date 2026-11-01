import type { Metadata } from "next";
import { notFound } from "next/navigation";
import "../globals.css";
export async function generateMetadata({ params }: { params: Promise<{ lang: string }> }): Promise<Metadata> {
  const { lang } = await params;
  return { title: `yorungez — ${lang === "en" ? "Sky" : "Gökyüzü"}`,
    description: lang === "en" ? "Explore the sky by place and time." : "Konum ve zamana göre gökyüzünü keşfet.", manifest:"/manifest.webmanifest", appleWebApp:{capable:true,title:"yorungez",statusBarStyle:"default"}, icons: { icon: "/favicon.svg",apple:"/pwa/icon-192.png" } };
}
export default async function RootLayout({ children, params }: { children: React.ReactNode; params: Promise<{ lang: string }> }) {
  const { lang } = await params;
  if (lang !== "tr" && lang !== "en") notFound();
  return <html lang={lang}><body>{children}</body></html>;
}
