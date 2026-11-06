import type { Metadata, Viewport } from "next";
import { notFound } from "next/navigation";
import ViewportMetrics from '../../components/ViewportMetrics';
import {brand} from '../../lib/brand';
import {siteUrl} from '../../lib/seo';
import MeasurementConsent from '../../components/MeasurementConsent';
import "../globals.css";
export const viewport:Viewport={width:'device-width',initialScale:1,viewportFit:'cover',interactiveWidget:'resizes-content',themeColor:'#3C3F43'};
export async function generateMetadata({ params }: { params: Promise<{ lang: string }> }): Promise<Metadata> {
  const { lang } = await params;
  return { metadataBase:new URL(siteUrl), verification:{other:{'msvalidate.01':'C5502FF1C29FC6AE5807445FE97964B6'}}, title: `Yorungez — ${lang === "en" ? "Sky" : "Gökyüzü"}`,
    description: lang === "en" ? "Explore the sky by place and time." : "Konum ve zamana göre gökyüzünü keşfet.", manifest:"/manifest.webmanifest", appleWebApp:{capable:true,title:"yorungez",statusBarStyle:"default"}, icons: { icon: [{url:brand.faviconIco.src,type:'image/x-icon',sizes:'16x16 32x32 48x48'},{url:brand.favicon32.src,type:'image/png',sizes:'32x32'},{url:brand.faviconSvg.src,type:'image/svg+xml',sizes:'any'}],apple:[{url:brand.apple180.src,type:'image/png',sizes:'180x180'}] } };
}
export default async function RootLayout({ children, params }: { children: React.ReactNode; params: Promise<{ lang: string }> }) {
  const { lang } = await params;
  if (lang !== "tr" && lang !== "en") notFound();
  return <html lang={lang}><body><ViewportMetrics/>{children}<MeasurementConsent language={lang}/></body></html>;
}
