import { notFound } from "next/navigation";
import SkyExplorer from "../../components/SkyExplorer";
import {pageMetadata,siteDescription,siteSchema,jsonLd} from '../../lib/seo';
export const dynamic='force-static';
export function generateStaticParams(){return [{lang:'en'},{lang:'tr'}]}
export async function generateMetadata({params}:{params:Promise<{lang:string}>}){const {lang}=await params;if(lang!=='en'&&lang!=='tr')notFound();return pageMetadata(lang,'',lang==='tr'?'Canlı gökyüzü haritası ve astronomi | Yorungez':'Live sky map & astronomy | Yorungez',siteDescription[lang]);}
export default async function Page({ params }: { params: Promise<{ lang: string }> }) {
  const { lang } = await params;
  if (lang !== "tr" && lang !== "en") notFound();
  return <><script type="application/ld+json" dangerouslySetInnerHTML={{__html:jsonLd(siteSchema(lang))}}/><SkyExplorer initialLanguage={lang} /></>;
}
