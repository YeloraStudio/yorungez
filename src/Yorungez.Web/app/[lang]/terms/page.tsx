import type {Metadata} from 'next';
import {notFound} from 'next/navigation';
import glossary from '../../../generated/glossary.json';
import BrandLogo from '../../../components/BrandLogo';
import GlossaryBrowser from '../../../components/GlossaryBrowser';
import {glossaryText} from '../../../lib/glossary.ts';
import {pageMetadata} from '../../../lib/seo';
export const dynamic='force-static';
export function generateStaticParams(){return [{lang:'en'},{lang:'tr'}]}
export async function generateMetadata({params}:{params:Promise<{lang:string}>}):Promise<Metadata>{
 const {lang}=await params;if(lang!=='en'&&lang!=='tr')notFound();
 return pageMetadata(lang,'/terms',`${glossaryText[lang].title} | Yorungez`,glossaryText[lang].intro);
}
export default async function TermsPage({params}:{params:Promise<{lang:string}>}){
 const {lang}=await params;if(lang!=='en'&&lang!=='tr')notFound();const t=glossaryText[lang];
 return <main className="glossary-page"><div className="glossary-page-inner"><header><a href={`/${lang}`} aria-label={t.back}><BrandLogo/></a><a href={`/${lang}`}>{t.back} ↗</a></header><h1>{t.title}</h1><p className="glossary-intro">{t.intro}</p><GlossaryBrowser terms={glossary} language={lang} standalone/></div></main>;
}
