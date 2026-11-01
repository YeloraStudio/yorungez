import { notFound } from "next/navigation";
import RendererLab from "../../../../components/RendererLab";
export const dynamic = "force-dynamic";
export default async function Page({ params }: { params: Promise<{ lang: string }> }) {
  const { lang } = await params;
  if (process.env.YORUNGEZ_ENABLE_LAB !== "1" || (lang !== "tr" && lang !== "en")) notFound();
  return <RendererLab language={lang} />;
}
