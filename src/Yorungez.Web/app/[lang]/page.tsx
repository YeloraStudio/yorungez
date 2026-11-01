import { notFound } from "next/navigation";
import SkyExplorer from "../../components/SkyExplorer";
export const dynamic='force-static';
export function generateStaticParams(){return [{lang:'en'},{lang:'tr'}]}
export default async function Page({ params }: { params: Promise<{ lang: string }> }) {
  const { lang } = await params;
  if (lang !== "tr" && lang !== "en") notFound();
  return <SkyExplorer initialLanguage={lang} />;
}
