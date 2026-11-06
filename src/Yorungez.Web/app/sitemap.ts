import type {MetadataRoute} from 'next';
import {guides,reviewed} from '../lib/knowledge';
import {siteUrl} from '../lib/seo';
export default function sitemap():MetadataRoute.Sitemap{
 const paths=['','/library','/terms','/about','/mobile','/privacy',...guides.map(g=>`/library/${g.slug}`)];
 return paths.flatMap(path=>(['en','tr'] as const).map(lang=>({url:`${siteUrl}/${lang}${path}`,lastModified:reviewed,alternates:{languages:{en:`${siteUrl}/en${path}`,tr:`${siteUrl}/tr${path}`,'x-default':`${siteUrl}/en${path}`}}})));
}
